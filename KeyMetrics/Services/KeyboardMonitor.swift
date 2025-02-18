import Foundation
import Cocoa

class KeyboardMonitor: ObservableObject {
    @Published var keyStats = KeyStats()
    @Published var isMonitoring = false
    @Published var latestKeyStroke: KeyStroke?
    @Published var currentSpeed: Int = 0 // 确保这个属性是 @Published
    
    private var eventTap: CFMachPort?
    private let statsQueue = DispatchQueue(label: "com.keymetrics.stats")
    private let saveInterval: TimeInterval = 60 // 每60秒保存一次数据
    private var lastEventTime: TimeInterval = 0
    private let minimumTimeBetweenEvents: TimeInterval = 0.05 // 50毫秒
    
    // 用于计算实时速度的属性
    private var keyPressTimestamps: [Date] = []
    
    private var lastProcessedKeyCode: Int = -1
    private var lastProcessedTime: TimeInterval = 0
    private let debounceInterval: TimeInterval = 0.1 // 100ms 防重复间隔
    
    init() {
        loadStats()
        checkAccessibilityPermissions()
        setupAutoSave()
        
        // 每秒更新一次速度，确保速度会随时间降低
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.calculateCurrentSpeed()
        }
    }
    
    public func loadStats() {
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
    
    private func calculateCurrentSpeed() {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        // 只保留最近一分钟的按键记录
        keyPressTimestamps = keyPressTimestamps.filter { $0 > oneMinuteAgo }
        
        // 当前速度就是最近一分钟内的按键数
        let speed = keyPressTimestamps.count
        
        // 在主线程更新 UI
        DispatchQueue.main.async {
            self.currentSpeed = speed
            self.objectWillChange.send() // 确保发送更新通知
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
        // 扩展事件监听范围，包含系统定义的热键和特殊按键
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue) // 添加对修饰键的监听
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                
                // 根据事件类型分别处理
                if type == .flagsChanged {
                    monitor.handleModifierKeyEvent(event)
                } else if type == .keyDown {
                    monitor.handleKeyEvent(event)
                }
                
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
            
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let currentTime = ProcessInfo.processInfo.systemUptime
            
            // 修改防抖逻辑
            // 1. 全局防抖降低到 30ms，以适应快速打字
            // 2. 同键防抖降低到 60ms，避免漏记实际的重复按键
            if (currentTime - self.lastProcessedTime) < 0.03 { // 30ms 全局防抖
                return
            }
            
            if keyCode == self.lastProcessedKeyCode && 
               (currentTime - self.lastProcessedTime) < 0.06 { // 60ms 同键防抖
                return
            }
            
            // 更新最后处理的按键信息
            self.lastProcessedKeyCode = keyCode
            self.lastProcessedTime = currentTime
            
            // 修饰键列表
            let modifierKeyCodes = Set([
                54, 55,  // Command (左右)
                56, 60,  // Shift (左右)
                58, 61,  // Option (左右)
                59,      // Control
                63      // Function
            ])
            
            // 如果是修饰键，直接返回
            if modifierKeyCodes.contains(keyCode) {
                return
            }
            
            // 记录按键并更新统计
            DispatchQueue.main.async {
                self.keyPressTimestamps.append(Date())
                self.calculateCurrentSpeed()
                
                let character = self.getKeyName(for: keyCode)
                let keyStroke = KeyStroke(keyCode: keyCode, character: character)
                self.latestKeyStroke = keyStroke
                self.updateStats(keyCode: keyCode)
            }
        }
    }
    
    private func handleModifierKeyEvent(_ event: CGEvent) {
        statsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let currentTime = ProcessInfo.processInfo.systemUptime
            let flags = event.flags
            
            // 使用相同的防抖逻辑
            if (currentTime - self.lastProcessedTime) < 0.03 { // 30ms 全局防抖
                return
            }
            
            if keyCode == self.lastProcessedKeyCode && 
               (currentTime - self.lastProcessedTime) < 0.06 { // 60ms 同键防抖
                return
            }
            
            // 检查修饰键是否真的被按下
            let isKeyDown = flags.contains(.maskCommand) ||
                           flags.contains(.maskShift) ||
                           flags.contains(.maskAlternate) ||
                           flags.contains(.maskControl)
            
            if isKeyDown {
                // 更新最后处理的按键信息
                self.lastProcessedKeyCode = keyCode
                self.lastProcessedTime = currentTime
                
                DispatchQueue.main.async {
                    self.keyPressTimestamps.append(Date())
                    self.calculateCurrentSpeed()
                    
                    let character = self.getKeyName(for: keyCode)
                    let keyStroke = KeyStroke(keyCode: keyCode, character: character)
                    self.latestKeyStroke = keyStroke
                    self.updateStats(keyCode: keyCode)
                }
            }
        }
    }
    
    private func updateStats(keyCode: Int) {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        // 更新总计数
        keyStats.totalCount += 1
        
        // 更新按键频率
        keyStats.keyFrequency[keyCode, default: 0] += 1
        
        // 更新每日统计
        keyStats.dailyStats[startOfDay, default: 0] += 1
        
        // 更新每日按键频率
        var dayFrequency = keyStats.dailyKeyFrequency[startOfDay] ?? [:]
        dayFrequency[keyCode, default: 0] += 1
        keyStats.dailyKeyFrequency[startOfDay] = dayFrequency
        
        // 更新每日详细统计
        keyStats.updateDailyDetail(for: now, keyCode: keyCode)
        
        // 检查是否是删除键
        if keyCode == 51 {
            keyStats.totalDeleteCount += 1
            
            let hourDate = calendar.startOfHour(for: now)
            keyStats.hourlyDeleteStats[hourDate, default: 0] += 1
        }
        
        let hourDate = calendar.startOfHour(for: now)
        keyStats.hourlyStats[hourDate, default: 0] += 1
        
        // 保存更新后的统计数据
        saveStats()
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
            // 第一行 Function 键（根据最新的 MacBook 键盘布局）
            53: "esc",
            122: "F1",     // 调节亮度减
            120: "F2",     // 调节亮度加
            160: "F3",     // 调度中心
            177: "F4",     // Spotlight
            176: "F5",     // 听写
            178: "F6",     // 勿扰模式
            130: "F7",     // 媒体后退
            131: "F8",     // 媒体播放/暂停
            132: "F9",     // 媒体前进
            133: "F10",    // 静音
            134: "F11",    // 音量减
            135: "F12",    // 音量加
            
            // 第二行数字键
            50: "`",
            18: "1",
            19: "2",
            20: "3",
            21: "4",
            23: "5",
            22: "6",
            26: "7",
            28: "8",
            25: "9",
            29: "0",
            27: "-",
            24: "=",
            51: "delete",
            
            // 第三行
            48: "tab",
            12: "Q",
            13: "W",
            14: "E",
            15: "R",
            17: "T",
            16: "Y",
            32: "U",
            34: "I",
            31: "O",
            35: "P",
            33: "[",
            30: "]",
            42: "\\",
            
            // 第四行
            57: "caps lock",
            0: "A",
            1: "S",
            2: "D",
            3: "F",
            5: "G",
            4: "H",
            38: "J",
            40: "K",
            37: "L",
            41: ";",
            39: "'",
            36: "return",
            
            // 第五行
            56: "shift_left",
            6: "Z",
            7: "X",
            8: "C",
            9: "V",
            11: "B",
            45: "N",
            46: "M",
            43: ",",
            47: ".",
            44: "/",
            60: "shift_right",  // 右 shift
            
            // 最后一行
            179: "fn",
            59: "control",
            58: "option_left",
            55: "command_left",
            49: "space",
            54: "command_right",  // 右 command
            61: "option_right",   // 右 option
            
            // 方向键
            126: "↑",
            125: "↓",
            123: "←",
            124: "→"
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
    
    deinit {
        // 清理定时器等资源
    }
    
    // 添加一个函数来检查特殊功能键
    private func isSpecialFunctionKey(_ keyCode: Int) -> Bool {
        let specialFunctionKeys = Set([
            160,  // F3 Mission Control
            177,  // F4 Spotlight
            176,  // F5 Dictation
            178,  // F6 Do Not Disturb
            // 可以根据需要添加其他特殊功能键
        ])
        return specialFunctionKeys.contains(keyCode)
    }
}

// 辅助扩展
extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day, .hour], from: date)
        return self.date(from: components) ?? date
    }
} 