import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate: Date? = nil
    @State private var showingDateDetail = false
    
    enum TimeRange {
        case day, week, month, year
    }
    
    var body: some View {
        VStack {
            Picker("时间范围", selection: $selectedTimeRange) {
                Text("日").tag(TimeRange.day)
                Text("周").tag(TimeRange.week)
                Text("月").tag(TimeRange.month)
                Text("年").tag(TimeRange.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Chart {
                ForEach(getHistoryData(), id: \.date) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Count", data.count)
                    )
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Count", data.count)
                    )
                    .opacity(0.1)
                }
            }
            .frame(height: 300)
            .padding()
            
            List {
                ForEach(getHistoryData().reversed(), id: \.date) { data in
                    HStack {
                        Text(formatDate(data.date))
                        Spacer()
                        Text("\(data.count) 次")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = data.date
                        showingDateDetail = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingDateDetail) {
            if let date = selectedDate {
                DayDetailView(date: date, keyStats: keyboardMonitor.keyStats)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func getHistoryData() -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let days: Int
        
        switch selectedTimeRange {
            case .day: days = 1
            case .week: days = 7
            case .month: days = 30
            case .year: days = 365
        }
        
        return (0..<days).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: -day, to: now) else { return nil }
            let startOfDay = calendar.startOfDay(for: date)
            return (date: startOfDay, count: keyboardMonitor.keyStats.dailyStats[startOfDay] ?? 0)
        }.reversed()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DayDetailView: View {
    let date: Date
    let keyStats: KeyStats
    @Environment(\.dismiss) private var dismiss
    
    // 获取按键名称的映射
    private let keyMap: [Int: String] = [
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
        56: "shift",
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
        60: "shift",  // 右 shift
        
        // 最后一行
        179: "fn",
        59: "control",
        58: "option",
        55: "command",
        49: "space",
        54: "command",  // 右 command
        61: "option",   // 右 option
        
        // 方向键
        126: "↑",
        125: "↓",
        123: "←",
        124: "→"
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和关闭按钮
                HStack {
                    Text(formatDate(date))
                        .font(.headline)
                    Spacer()
                    Button("关闭") {
                        dismiss()
                    }
                }
                .padding(.horizontal)
                
                if let dayStats = getDayStats(), dayStats.count > 0 {
                    // 基础统计信息
                    HStack(spacing: 20) {
                        StatCard(
                            title: "总按键",
                            value: "\(dayStats.count)",
                            icon: "keyboard",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "独特按键",
                            value: "\(getUniqueKeysCount())",
                            icon: "number",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // 按键分布
                    VStack(alignment: .leading) {
                        Text("按键分布")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(getKeyDistribution(), id: \.key) { item in
                                    VStack(alignment: .center) {
                                        Text(item.key)
                                            .font(.system(.body, design: .monospaced))
                                        Text("\(item.count)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 按键使用趋势图
                    VStack(alignment: .leading) {
                        Text("使用趋势")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(getKeyDistribution(), id: \.key) { item in
                                BarMark(
                                    x: .value("Key", item.key),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(by: .value("Key", item.key))
                            }
                        }
                        .frame(height: 200)
                        .padding()
                    }
                } else {
                    Text("这一天没有按键记录")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .frame(width: 600, height: 500)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func getDayStats() -> (date: Date, count: Int)? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        if let count = keyStats.dailyStats[startOfDay] {
            return (date: startOfDay, count: count)
        }
        return nil
    }
    
    private func getUniqueKeysCount() -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        // 只统计当天的独特按键数量
        let dayKeys = keyStats.keyFrequency.filter { key, _ in
            // 这里需要添加日期过滤逻辑
            true // 暂时返回所有，需要修改 KeyStats 结构来支持按日期过滤
        }
        return dayKeys.count
    }
    
    private func getKeyDistribution() -> [(key: String, count: Int)] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        // 转换按键码为可读名称
        return keyStats.keyFrequency
            .map { keyCode, count in
                (key: keyMap[keyCode] ?? "Key \(keyCode)", count: count)
            }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }
} 