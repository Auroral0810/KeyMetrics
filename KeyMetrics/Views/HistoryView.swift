import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDate: Date? = nil
    @State private var showingDateDetail = false
    
    enum TimeRange: String, CaseIterable {
        case day
        case week
        case month
        case year
        
        var localizedName: String {
            switch self {
            case .day:
                return LanguageManager.shared.localizedString("Day")
            case .week:
                return LanguageManager.shared.localizedString("Week")
            case .month:
                return LanguageManager.shared.localizedString("Month")
            case .year:
                return LanguageManager.shared.localizedString("Year")
            }
        }
    }
    
    var body: some View {
        VStack {
            Picker(languageManager.localizedString("Time Range"), selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.localizedName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorMultiply(themeManager.isDarkMode ? .white : .black)
            .padding()
            
            Chart {
                ForEach(getHistoryData(), id: \.date) { data in
                    LineMark(
                        x: .value(languageManager.localizedString("Date"), data.date, unit: .day),
                        y: .value(languageManager.localizedString("Count"), data.count)
                    )
                    
                    AreaMark(
                        x: .value(languageManager.localizedString("Date"), data.date, unit: .day),
                        y: .value(languageManager.localizedString("Count"), data.count)
                    )
                    .opacity(0.1)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatShortDate(date))
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 300)
            .padding()
            
            List {
                ForEach(getHistoryData().reversed(), id: \.date) { data in
                    HStack {
                        Text(formatDate(data.date))
                        Spacer()
                        Text(String(format: languageManager.localizedString("Times Format"), data.count))
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
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch languageManager.currentLanguage {
        case .english:
            formatter.dateFormat = "MMM d"
        case .simplifiedChinese, .traditionalChinese:
            formatter.dateFormat = "M月d日"
        case .japanese:
            formatter.dateFormat = "M月d日"
        case .korean:
            formatter.dateFormat = "M월 d일"
        case .auto:
            formatter.dateFormat = "M月d日"
        }
        
        formatter.locale = Locale(identifier: languageManager.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: languageManager.currentLanguage.rawValue)
        return formatter.string(from: date)
    }
}

struct DayDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    let date: Date
    let keyStats: KeyStats
    @Environment(\.dismiss) private var dismiss
    
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
    
    private struct ChartLegend: Identifiable {
        let id = UUID()
        let key: String
        let color: Color
    }
    
    private func getLegendItems() -> [ChartLegend] {
        return getKeyDistribution().enumerated().map { index, item in
            ChartLegend(
                key: item.key,
                color: chartColors[index % chartColors.count]
            )
        }
    }
    
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
                HStack {
                    Text(formatDate(date))
                        .font(.headline)
                        .foregroundStyle(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text(languageManager.localizedString("Close"))
                            .foregroundStyle(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                }
                .padding(.horizontal)
                
                if let dayStats = getDayStats(), dayStats.count > 0 {
                    HStack(spacing: 20) {
                        StatCard(
                            title: languageManager.localizedString("Total Keys"),
                            value: "\(dayStats.count)",
                            icon: "keyboard",
                            color: .blue
                        )
                        
                        StatCard(
                            title: languageManager.localizedString("Unique Keys"),
                            value: "\(getUniqueKeysCount())",
                            icon: "number",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text(languageManager.localizedString("Key Distribution"))
                            .font(.headline)
                            .foregroundStyle(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(getKeyDistribution(), id: \.key) { item in
                                    VStack(alignment: .center) {
                                        Text(item.key)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                                        Text("\(item.count)")
                                            .font(.caption)
                                            .foregroundStyle(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text(languageManager.localizedString("Usage Trend"))
                            .font(.headline)
                            .foregroundStyle(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
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
                    Text(languageManager.localizedString("No Records"))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .frame(width: 600, height: 500)
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
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
        if let dailyDetail = keyStats.getDailyDetail(for: date) {
            return dailyDetail.uniqueKeysCount
        }
        return 0
    }
    
    private func getKeyDistribution() -> [(key: String, count: Int)] {
        if let dailyDetail = keyStats.getDailyDetail(for: date) {
            return dailyDetail.topTenKeys.map { keyCount in
                let keyName = keyMap[keyCount.keyCode] ?? "Key \(keyCount.keyCode)"
                return (key: keyName, count: keyCount.count)
            }
        }
        return []
    }
} 