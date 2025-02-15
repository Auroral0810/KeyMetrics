import Foundation
import Cocoa

class KeyboardMonitor: ObservableObject {
    @Published var keyStats = KeyStats()
    @Published var isMonitoring = false
    @Published var latestKeyStroke: KeyStroke?
    
    private var eventTap: CFMachPort?
    private let statsQueue = DispatchQueue(label: "com.keymetrics.stats")
    private let saveInterval: TimeInterval = 60 // 每60秒保存一次数据
    private var lastEventTime: TimeInterval = 0
    private let minimumTimeBetweenEvents: TimeInterval = 0.05 // 50毫秒
    
    init() {
        loadStats()
        checkAccessibilityPermissions()
        setupAutoSave()
    }
    
    private func loadStats() {
        let url = getDocumentsDirectory().appendingPathComponent("keystats.json")
        if let data = try? Data(contentsOf: url),
           let loadedStats = try? JSONDecoder().decode(KeyStats.self, from: data) {
            DispatchQueue.main.async {
                self.keyStats = loadedStats
            }
        }
    }
    
    private func setupAutoSave() {
        Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            self?.saveStats()
        }
    }
    
    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if accessEnabled {
            setupEventTap()
        } else {
            DispatchQueue.main.async {
                self.isMonitoring = false
            }
        }
    }
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleKeyEvent(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            DispatchQueue.main.async {
                self.isMonitoring = false
            }
            return
        }
        
        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        DispatchQueue.main.async {
            self.isMonitoring = true
        }
    }
    
    func startMonitoring() {
        if !isMonitoring {
            checkAccessibilityPermissions()
        }
    }
    
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
            DispatchQueue.main.async {
                self.isMonitoring = false
            }
        }
    }
    
    private func handleKeyEvent(_ event: CGEvent) {
        statsQueue.async { [weak self] in
            guard let self = self else { return }
            
            if event.type != .keyDown {
                return
            }
            
            let currentTime = ProcessInfo.processInfo.systemUptime
            if (currentTime - self.lastEventTime) < self.minimumTimeBetweenEvents {
                return
            }
            
            self.lastEventTime = currentTime
            
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            
            // 过滤掉修饰键
            let modifierKeyCodes = Set([54, 55, 56, 57, 58, 59, 60, 61, 62, 63])
            if modifierKeyCodes.contains(Int(keyCode)) {
                return
            }
            
            // 创建新的 KeyStroke
            let character = self.getKeyName(for: Int(keyCode))
            let keyStroke = KeyStroke(keyCode: Int(keyCode), character: character)
            
            DispatchQueue.main.async {
                self.latestKeyStroke = keyStroke
                self.updateStats(keyCode: Int(keyCode))
            }
        }
    }
    
    private func updateStats(keyCode: Int) {
        keyStats.totalCount += 1
        keyStats.keyFrequency[keyCode, default: 0] += 1
        
        // 检查是否是删除键
        if keyCode == 51 { // 51 是删除键的 keyCode
            keyStats.totalDeleteCount += 1
            
            let now = Date()
            let calendar = Calendar.current
            let hourDate = calendar.startOfHour(for: now)
            keyStats.hourlyDeleteStats[hourDate, default: 0] += 1
        }
        
        let now = Date()
        let calendar = Calendar.current
        let hourDate = calendar.startOfHour(for: now)
        let dayDate = calendar.startOfDay(for: now)
        
        keyStats.hourlyStats[hourDate, default: 0] += 1
        keyStats.dailyStats[dayDate, default: 0] += 1
        
        objectWillChange.send()
    }
    
    private func saveStats() {
        // 将统计数据保存到本地
        if let data = try? JSONEncoder().encode(keyStats) {
            let url = getDocumentsDirectory().appendingPathComponent("keystats.json")
            try? data.write(to: url)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getKeyName(for keyCode: Int) -> String {
        let keyMap: [Int: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
            8: "c", 9: "v", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
            16: "y", 17: "t", 32: "u", 31: "o", 35: "p", 37: "l", 38: "j",
            40: "k", 46: "m", 49: "Space"
            // 可以根据需要添加更多键映射
        ]
        return keyMap[keyCode] ?? "Key \(keyCode)"
    }
    
    func clearStats() {
        DispatchQueue.main.async { [weak self] in
            self?.keyStats = KeyStats()
            self?.saveStats()
        }
    }
    
    func exportStats() -> URL? {
        if let data = try? JSONEncoder().encode(keyStats) {
            let url = getDocumentsDirectory().appendingPathComponent("keystats_export.json")
            try? data.write(to: url)
            return url
        }
        return nil
    }
}

// 辅助扩展
extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day, .hour], from: date)
        return self.date(from: components) ?? date
    }
} 