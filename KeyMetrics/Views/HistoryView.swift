import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate: Date? = nil
    @State private var showingDateDetail = false
    
    enum TimeRange: String, CaseIterable {
        case day = "天"
        case week = "周"
        case month = "月"
        case year = "年"
    }
    
    var body: some View {
        VStack {
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorMultiply(themeManager.isDarkMode ? .white : .black)
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
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    .listRowBackground(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = data.date
                        showingDateDetail = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
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
    @EnvironmentObject var themeManager: ThemeManager
    let date: Date
    let keyStats: KeyStats
    @Environment(\.dismiss) private var dismiss
    
    // 预定义颜色数组
    private let chartColors: [Color] = [
        .blue,      // 主要的蓝色
        .green,     // 鲜艳的绿色
        .orange,    // 橙色
        .purple,    // 紫色
        .red,       // 红色
        .cyan,      // 青色
        .yellow,    // 黄色
        .indigo,    // 靛蓝色
        .mint,      // 薄荷绿
        .pink,      // 粉色
        .gray       // 其他类别使用的灰色
    ]
    
    // 为图例创建数据模型
    private struct ChartLegend: Identifiable {
        let id = UUID()
        let key: String
        let color: Color
    }
    
    // 获取图例数据
    private func getLegendItems() -> [ChartLegend] {
        return getKeyDistribution().enumerated().map { index, item in
            ChartLegend(
                key: item.key,
                color: chartColors[index % chartColors.count]
            )
        }
    }
    
    // 获取按键名称的映射
    private let keyMap: [Int: String] = [
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
                        
                        let chart = Chart {
                            ForEach(getKeyDistribution(), id: \.key) { item in
                                BarMark(
                                    x: .value("Key", item.key),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(by: .value("Key", item.key))
                                .cornerRadius(8)
                            }
                        }
                        
                        let textColor = ThemeManager.ThemeColors.text(themeManager.isDarkMode)
                        
                        chart
                            .chartForegroundStyleScale(range: chartColors)
                            .chartLegend(position: .bottom, alignment: .center, spacing: 12) {
                                HStack(spacing: 8) {
                                    ForEach(getLegendItems()) { item in
                                        Label(
                                            title: { 
                                                Text(item.key)
                                                    .font(.caption)
                                                    .foregroundStyle(textColor)
                                            },
                                            icon: {
                                                Circle()
                                                    .fill(item.color)
                                                    .frame(width: 8, height: 8)
                                            }
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                        .foregroundStyle(textColor.opacity(0.1))
                                    AxisValueLabel()
                                        .foregroundStyle(textColor)
                                        .font(.system(size: 10, weight: .medium))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                        .foregroundStyle(textColor.opacity(0.1))
                                    AxisValueLabel()
                                        .foregroundStyle(textColor)
                                        .font(.system(size: 10, weight: .medium))
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
        
        // 获取当天的按键统计
        if let dayStats = keyStats.dailyStats[startOfDay] {
            // 获取当天有使用记录的不同按键数量
            let uniqueKeys = Set(keyStats.keyFrequency.keys.filter { keyCode in
                keyStats.keyFrequency[keyCode] ?? 0 > 0
            })
            return uniqueKeys.count
        }
        return 0
    }
    
    private func getKeyDistribution() -> [(key: String, count: Int)] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        // 获取当天的按键统计
        if let dayStats = keyStats.dailyStats[startOfDay] {
            // 创建临时数组来存储结果
            var distribution: [(key: String, count: Int)] = []
            
            // 遍历所有按键
            for (keyCode, totalCount) in keyStats.keyFrequency {
                if totalCount > 0 {
                    let keyName = keyMap[keyCode] ?? "Key \(keyCode)"
                    distribution.append((key: keyName, count: totalCount))
                }
            }
            
            // 排序并获取前10个
            let sortedDistribution = distribution.sorted { $0.count > $1.count }
            return Array(sortedDistribution.prefix(10))
        }
        
        return []
    }
} 