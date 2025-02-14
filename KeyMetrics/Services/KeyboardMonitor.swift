import Foundation
import Cocoa

class KeyboardMonitor: ObservableObject {
    @Published var keyStats = KeyStats(totalCount: 0, keyFrequency: [:], hourlyStats: [:], dailyStats: [:])
    private var eventTap: CFMachPort?
    private let statsQueue = DispatchQueue(label: "com.keymetrics.stats")
    private let saveInterval: TimeInterval = 60 // 每60秒保存一次数据
    
    init() {
        loadStats()
        setupEventTap()
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
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                monitor.handleKeyEvent(event)
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleKeyEvent(_ event: CGEvent) {
        statsQueue.async { [weak self] in
            guard let self = self else { return }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            self.updateStats(keyCode: Int(keyCode))
        }
    }
    
    private func updateStats(keyCode: Int) {
        keyStats.totalCount += 1
        keyStats.keyFrequency[keyCode, default: 0] += 1
        
        let now = Date()
        let calendar = Calendar.current
        let hourDate = calendar.startOfHour(for: now)
        let dayDate = calendar.startOfDay(for: now)
        
        keyStats.hourlyStats[hourDate, default: 0] += 1
        keyStats.dailyStats[dayDate, default: 0] += 1
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
        statsQueue.async { [weak self] in
            guard let self = self else { return }
            self.keyStats = KeyStats(totalCount: 0, keyFrequency: [:], hourlyStats: [:], dailyStats: [:])
            self.saveStats()
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