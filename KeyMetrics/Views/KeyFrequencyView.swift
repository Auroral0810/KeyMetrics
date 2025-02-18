import SwiftUI
import Charts
import UniformTypeIdentifiers

struct KeyFrequencyView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingExportSheet = false
    @State private var hoveredKey: String? = nil
    @State private var selectedChartType: ChartType = .donut
    
    enum TimeRange: String, CaseIterable {
        case day = "Last 24 Hours"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var description: String {
            LanguageManager.shared.localizedString(self.rawValue)
        }
    }
    
    enum ChartType: String, CaseIterable {
        case donut = "Donut Chart"
        case bar = "Bar Chart"
        case line = "Line Chart"
        
        var description: String {
            LanguageManager.shared.localizedString(self.rawValue)
        }
    }
    
    var sortedKeyFrequency: [(key: String, count: Int)] {
        let now = Date()
        let calendar = Calendar.current
        
        let startDate: Date
        switch selectedTimeRange {
        case .day:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            startDate = .distantPast
        }
        
        var filteredFrequency: [Int: Int] = [:]
        for (date, keyFreq) in keyboardMonitor.keyStats.dailyKeyFrequency {
            if date >= startDate && date <= now {
                for (key, count) in keyFreq {
                    filteredFrequency[key, default: 0] += count
                }
            }
        }
        
        // 合并相同按键的计数
        var mergedFrequency: [String: Int] = [:]
        for (keyCode, count) in filteredFrequency {
            let keyName = keyboardMonitor.getKeyName(for: keyCode)
            mergedFrequency[keyName, default: 0] += count
        }
        
        return mergedFrequency
            .map { (key: $0.key, count: $0.value) }
            .sorted { item1, item2 in
                if item1.count == item2.count {
                    return item1.key < item2.key
                }
                return item1.count > item2.count
            }
    }
    
    var timeRangeStats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String) {
        let data = sortedKeyFrequency
        let totalCount = data.reduce(0) { $0 + $1.count }
        let uniqueKeys = data.count
        let topKey = data.first?.key ?? "-"
        
        return (
            totalCount: totalCount,
            uniqueKeys: uniqueKeys,
            mostUsedKey: topKey
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部控制栏
            HStack {
                Picker(languageManager.localizedString("Time Range"), selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.description)
                            .font(fontManager.getFont(size: 12))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(themeManager.isDarkMode ? .white : .black)
                
                Spacer()
                
                Picker(languageManager.localizedString("Chart Type"), selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.description)
                            .font(fontManager.getFont(size: 12))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .colorMultiply(themeManager.isDarkMode ? .white : .black)
                
                Button(action: { showingExportSheet = true }) {
                    Label(languageManager.localizedString("Export"), systemImage: "square.and.arrow.up")
                        .font(fontManager.getFont(size: 12))
                }
                .buttonStyle(.bordered)
                .colorMultiply(themeManager.isDarkMode ? .white : .black)
            }
            .padding()
            .background(themeManager.isDarkMode ? ThemeManager.ThemeColors.cardBackground(true) : Color(.lightGray).opacity(0.1))
            .cornerRadius(12)
            
            HStack(spacing: 20) {
                // 左侧统计卡片，使用时间范围统计数据
                VStack(spacing: 16) {
                    StatCard(
                        title: String(format: languageManager.localizedString("%@ Total"), selectedTimeRange.description),
                        value: "\(timeRangeStats.totalCount)",
                        icon: "keyboard",
                        color: .blue
                    )
                    
                    StatCard(
                        title: String(format: languageManager.localizedString("%@ Unique"), selectedTimeRange.description),
                        value: "\(timeRangeStats.uniqueKeys)",
                        icon: "number",
                        color: .green
                    )
                    
                    StatCard(
                        title: String(format: languageManager.localizedString("%@ Most Used"), selectedTimeRange.description),
                        value: timeRangeStats.mostUsedKey,
                        icon: "star",
                        color: .yellow
                    )
                }
                .frame(width: 200)
                
                // 主图表区域
                VStack {
                    switch selectedChartType {
                    case .donut:
                        DonutChart(
                            data: sortedKeyFrequency.prefix(10),
                            hoveredKey: $hoveredKey,
                            totalKeyCount: sortedKeyFrequency.reduce(0) { $0 + $1.count }
                        )
                    case .bar:
                        BarChart(data: sortedKeyFrequency.prefix(10), hoveredKey: $hoveredKey)
                    case .line:
                        LineChart(data: sortedKeyFrequency.prefix(10), hoveredKey: $hoveredKey)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 右侧排行榜
                VStack(alignment: .leading, spacing: 16) {
                    Text(languageManager.localizedString("TOP 10 Keys"))
                        .font(fontManager.getFont(size: 16))
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    
                    // 获取实际的按键数据
                    let actualData = sortedKeyFrequency.prefix(10)
                    // 计算需要填充的占位符数量
                    let placeholderCount = 10 - actualData.count
                    
                    // 显示实际数据
                    ForEach(Array(actualData.enumerated()), id: \.element.key) { index, item in
                        RankingRow(
                            rank: index + 1,
                            key: item.key,
                            count: item.count,
                            total: sortedKeyFrequency.first?.count ?? 1,
                            isHovered: hoveredKey == item.key
                        )
                        .onHover { isHovered in
                            hoveredKey = isHovered ? item.key : nil
                        }
                    }
                    
                    // 显示占位符
                    ForEach(0..<placeholderCount, id: \.self) { index in
                        RankingRow(
                            rank: actualData.count + index + 1,
                            key: "-",
                            count: 0,
                            total: sortedKeyFrequency.first?.count ?? 1,
                            isHovered: false
                        )
                        .opacity(0.3)  // 降低占位符的透明度
                    }
                }
                .frame(width: 250)
            }
        }
        .padding()
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
    }
}

// 统计卡片组件
struct StatCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(fontManager.getFont(size: 12))
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                
                Text(value)
                    .font(fontManager.getFont(size: 16))
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(12)
    }
}

// 排行榜行组件
struct RankingRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    let rank: Int
    let key: String
    let count: Int
    let total: Int
    let isHovered: Bool
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(fontManager.getFont(size: 14))
                .bold()
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                .frame(width: 30)
            
            Text(key)
                .font(fontManager.getFont(size: 14))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            Spacer()
            
            Text(String(format: languageManager.localizedString("Times Format"), count))
                .font(fontManager.getFont(size: 12))
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

// 所有图表共用的颜色数组
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

// 环形图组件
struct DonutChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    let data: ArraySlice<(key: String, count: Int)>
    @Binding var hoveredKey: String?
    private let totalKeyCount: Int
    
    // 为图例创建数据模型
    struct ChartLegend: Identifiable {
        let id = UUID()
        let key: String
        let color: Color
    }
    
    // 获取图例数据
    func getLegendItems() -> [ChartLegend] {
        return chartData.enumerated().map { index, item in
            ChartLegend(
                key: item.key,
                color: item.key == languageManager.localizedString("Others") ? chartColors.last! : chartColors[index]
            )
        }
    }
    
    private var chartData: [(key: String, count: Int)] {
        let top10Data = Array(data)
        let top10Total = top10Data.reduce(0) { $0 + $1.count }
        let othersCount = totalKeyCount - top10Total
        
        if othersCount > 0 {
            var combinedData = top10Data
            combinedData.append((key: languageManager.localizedString("Others"), count: othersCount))
            return combinedData
        }
        return top10Data
    }
    
    init(data: ArraySlice<(key: String, count: Int)>, hoveredKey: Binding<String?>, totalKeyCount: Int) {
        self.data = data
        self._hoveredKey = hoveredKey
        self.totalKeyCount = totalKeyCount
    }
    
    private func calculatePercentage(count: Int) -> Double {
        return Double(count) / Double(totalKeyCount) * 100
    }
    
    var body: some View {
        let chart = Chart {
            ForEach(chartData, id: \.key) { item in
                SectorMark(
                    angle: .value(languageManager.localizedString("Count"), item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value(languageManager.localizedString("Key"), item.key))
                .opacity(hoveredKey == nil || hoveredKey == item.key ? 1 : 0.3)
                .annotation(position: .overlay) {
                    if hoveredKey == item.key {
                        VStack(spacing: 4) {
                            Text(item.key)
                                .font(.system(size: 12, weight: .bold))
                            Text(String(format: languageManager.localizedString("Times Format"), item.count))
                                .font(.system(size: 11))
                            Text(String(format: "%.1f%%", calculatePercentage(count: item.count)))
                                .font(.system(size: 11))
                        }
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.key == languageManager.localizedString("Others") {
                        Text(String(format: "%.1f%%", calculatePercentage(count: item.count)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                }
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
                                    .font(fontManager.getFont(size: 10))
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
            .frame(height: 300)
    }
}

// 柱状图组件
struct BarChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    let data: ArraySlice<(key: String, count: Int)>
    @Binding var hoveredKey: String?
    
    // 为图例创建数据模型
    private struct ChartLegend: Identifiable {
        let id = UUID()
        let key: String
        let color: Color
    }
    
    // 获取图例数据，确保颜色与柱状图对应
    private func getLegendItems() -> [ChartLegend] {
        return Array(data.enumerated()).map { index, item in
            ChartLegend(
                key: item.key,
                color: chartColors[index]
            )
        }
    }
    
    var body: some View {
        let chart = Chart {
            ForEach(Array(data.enumerated()), id: \.element.key) { index, item in
                BarMark(
                    x: .value(languageManager.localizedString("Key"), item.key),
                    y: .value(languageManager.localizedString("Count"), item.count)
                )
                .foregroundStyle(by: .value(languageManager.localizedString("Key"), item.key))
                .cornerRadius(8)
                .opacity(hoveredKey == nil || hoveredKey == item.key ? 1 : 0.3)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                .annotation(position: .top, alignment: .center, spacing: 4) {
                    if hoveredKey == item.key {
                        VStack(spacing: 2) {
                            Text(String(format: languageManager.localizedString("Times Format"), item.count))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text(item.key)
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.8))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
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
                                    .font(fontManager.getFont(size: 10))
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
            .frame(height: 300)
            .padding(.top, 20)
            .animation(.easeInOut, value: hoveredKey)
    }
}

// 折线图组件
struct LineChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    let data: ArraySlice<(key: String, count: Int)>
    @Binding var hoveredKey: String?
    
    // 为图例创建数据模型
    private struct ChartLegend: Identifiable {
        let id = UUID()
        let key: String
        let color: Color
    }
    
    // 获取图例数据
    private func getLegendItems() -> [ChartLegend] {
        return Array(data.enumerated()).map { index, item in
            ChartLegend(
                key: item.key,
                color: chartColors[index]
            )
        }
    }
    
    var body: some View {
        let chart = Chart {
            ForEach(Array(data.enumerated()), id: \.element.key) { index, item in
                LineMark(
                    x: .value(languageManager.localizedString("Key"), item.key),
                    y: .value(languageManager.localizedString("Count"), item.count)
                )
                .foregroundStyle(chartColors[index])
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
                
                PointMark(
                    x: .value(languageManager.localizedString("Key"), item.key),
                    y: .value(languageManager.localizedString("Count"), item.count)
                )
                .foregroundStyle(chartColors[index])
                .symbolSize(60)
                .annotation(position: .top) {
                    Text(String(format: languageManager.localizedString("Times Format"), item.count))
                        .font(.system(size: 12))
                        .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                        .padding(4)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        
        let textColor = ThemeManager.ThemeColors.text(themeManager.isDarkMode)
        
        chart
            .chartLegend(position: .bottom, alignment: .center, spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(getLegendItems()) { item in
                        Label(
                            title: { 
                                Text(item.key)
                                    .font(fontManager.getFont(size: 10))
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
                    AxisGridLine().foregroundStyle(textColor)
                    AxisValueLabel().foregroundStyle(textColor)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(textColor)
                    AxisValueLabel().foregroundStyle(textColor)
                }
            }
            .frame(height: 300)
    }
}

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    @State private var exportFormat: ExportFormat = .txt
    @State private var selectedTimeRange: TimeRange = .day
    @State private var isExporting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum ExportFormat: String, CaseIterable {
        case txt = "TXT"
        case csv = "CSV"
    }
    
    enum TimeRange: String, CaseIterable {
        case day = "Last 24 Hours"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var description: String {
            LanguageManager.shared.localizedString(self.rawValue)
        }
    }
    
    // 计算当前选择时间范围内的统计数据
    private var timeRangeStats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String) {
        let now = Date()
        let calendar = Calendar.current
        
        let startDate: Date
        switch selectedTimeRange {
        case .day:
            startDate = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            startDate = .distantPast
        }
        
        var filteredFrequency: [Int: Int] = [:]
        for (date, keyFreq) in keyboardMonitor.keyStats.dailyKeyFrequency {
            if date >= startDate && date <= now {
                for (key, count) in keyFreq {
                    filteredFrequency[key, default: 0] += count
                }
            }
        }
        
        let totalCount = filteredFrequency.values.reduce(0, +)
        let uniqueKeys = filteredFrequency.keys.count
        let mostUsedKey = filteredFrequency.max(by: { $0.value < $1.value })?.key ?? 0
        
        return (
            totalCount: totalCount,
            uniqueKeys: uniqueKeys,
            mostUsedKey: keyboardMonitor.getKeyName(for: mostUsedKey)
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题区域
            HStack {
                Text(languageManager.localizedString("Export Data"))
                    .font(fontManager.getFont(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 主要内容区域
            VStack(spacing: 24) {
                // 时间范围选择
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(languageManager.localizedString("Select Time Range"))
                            .font(fontManager.getFont(size: 14))
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                    
                    Picker(languageManager.localizedString("Time Range"), selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.description)
                                .font(fontManager.getFont(size: 12))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorMultiply(themeManager.isDarkMode ? .white : .black)
                }
                
                // 导出格式选择
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                        Text(languageManager.localizedString("Export Format"))
                            .font(fontManager.getFont(size: 14))
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                    
                    Picker(languageManager.localizedString("Format"), selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                                .font(fontManager.getFont(size: 12))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorMultiply(themeManager.isDarkMode ? .white : .black)
                }
                
                // 数据统计
                VStack(alignment: .leading, spacing: 16) {
                    Text(languageManager.localizedString("Statistics"))
                        .font(fontManager.getFont(size: 14))
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    
                    VStack(spacing: 12) {
                        StatCard(
                            title: languageManager.localizedString("Total Keys"),
                            value: "\(timeRangeStats.totalCount)",
                            icon: "keyboard",
                            color: .blue
                        )
                        .font(fontManager.getFont(size: 12))
                        
                        StatCard(
                            title: languageManager.localizedString("Unique Keys"),
                            value: "\(timeRangeStats.uniqueKeys)",
                            icon: "number",
                            color: .green
                        )
                        .font(fontManager.getFont(size: 12))
                        
                        StatCard(
                            title: languageManager.localizedString("Most Used Key"),
                            value: timeRangeStats.mostUsedKey,
                            icon: "star.fill",
                            color: .yellow
                        )
                        .font(fontManager.getFont(size: 12))
                    }
                }
            }
            .padding()
            .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
            .cornerRadius(12)
            
            Spacer()
            
            // 底部按钮区域
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Text(languageManager.localizedString("Close"))
                        .font(fontManager.getFont(size: 12))
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                
                Button(action: exportData) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? languageManager.localizedString("Exporting...") : languageManager.localizedString("Export"))
                            .font(fontManager.getFont(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
            }
            .padding()
        }
        .frame(width: 500)
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .alert(alertMessage, isPresented: $showAlert) {
            Button(languageManager.localizedString("OK"), role: .cancel) {
                
            }
            .font(fontManager.getFont(size: 12))
        }
    }
    
    private func getStartDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .day:
            return calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            return .distantPast
        }
    }
    
    private func prepareKeyFrequencyData(startDate: Date, endDate: Date) -> [KeyFrequencyData] {
        var frequencyMap: [Int: Int] = [:]
        
        // 统计时间范围内的按键频率
        for (date, keyFreq) in keyboardMonitor.keyStats.dailyKeyFrequency {
            if date >= startDate && date <= endDate {
                for (key, count) in keyFreq {
                    frequencyMap[key, default: 0] += count
                }
            }
        }
        
        // 转换为 KeyFrequencyData 数组并排序
        return frequencyMap.map { key, count in
            KeyFrequencyData(
                keyCode: key,
                keyName: keyboardMonitor.getKeyName(for: key),
                count: count
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func exportData() {
        // 获取所有按键数据并排序
        let allKeyFrequency = prepareKeyFrequencyData(startDate: getStartDate(), endDate: Date())
        let top10Keys = Array(allKeyFrequency.prefix(10))
        
        // 根据选择的格式生成内容
        let content: String
        if exportFormat == .txt {
            content = generateTxtContent(stats: timeRangeStats, top10: top10Keys, allKeys: allKeyFrequency)
        } else {
            content = generateCsvContent(stats: timeRangeStats, top10: top10Keys, allKeys: allKeyFrequency)
        }
        
        let tempFile: URL
        do {
            // 创建临时文件
            tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent("keyboard_stats")
                .appendingPathExtension(exportFormat.rawValue.lowercased())
            
            // 写入内容
            try content.write(to: tempFile, atomically: true, encoding: .utf8)
            
            // 分享文件
            let controller = NSWorkspace.shared.activateFileViewerSelecting([tempFile])
            
            alertMessage = languageManager.localizedString("File saved to temporary directory")
            showAlert = true
        } catch {
            alertMessage = languageManager.localizedString("Export failed") + ": \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // 生成TXT格式内容
    private func generateTxtContent(stats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String),
                                  top10: [KeyFrequencyData],
                                  allKeys: [KeyFrequencyData]) -> String {
        var content = """
        \(languageManager.localizedString("Time Range")): \(selectedTimeRange.description)
        
        \(languageManager.localizedString("Statistics Summary")):
        \(languageManager.localizedString("Total Keys")): \(stats.totalCount)
        \(languageManager.localizedString("Unique Keys")): \(stats.uniqueKeys)
        \(languageManager.localizedString("Most Used Key")): \(stats.mostUsedKey)
        
        \(languageManager.localizedString("TOP 10 Keys Statistics")):
        """
        
        for (index, key) in top10.enumerated() {
            content += "\n\(index + 1). \(key.keyName): \(key.count) \(languageManager.localizedString("Times"))"
        }
        
        content += "\n\n\(languageManager.localizedString("All Keys Statistics")):"
        
        for key in allKeys {
            content += "\n\(key.keyName): \(key.count) \(languageManager.localizedString("Times"))"
        }
        
        return content
    }
    
    // 生成CSV格式内容
    private func generateCsvContent(stats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String),
                                  top10: [KeyFrequencyData],
                                  allKeys: [KeyFrequencyData]) -> String {
        var content = """
        \(languageManager.localizedString("Data Type")),\(languageManager.localizedString("Value"))
        \(languageManager.localizedString("Time Range")),\(selectedTimeRange.description)
        \(languageManager.localizedString("Total Keys")),\(stats.totalCount)
        \(languageManager.localizedString("Unique Keys")),\(stats.uniqueKeys)
        \(languageManager.localizedString("Most Used Key")),\(stats.mostUsedKey)
        
        \(languageManager.localizedString("TOP 10 Keys Statistics"))
        \(languageManager.localizedString("Rank")),\(languageManager.localizedString("Key")),\(languageManager.localizedString("Count"))
        """
        
        for (index, key) in top10.enumerated() {
            content += "\n\(index + 1),\(key.keyName),\(key.count)"
        }
        
        content += "\n\n\(languageManager.localizedString("All Keys Statistics"))"
        content += "\n\(languageManager.localizedString("Key")),\(languageManager.localizedString("Count"))"
        
        for key in allKeys {
            content += "\n\(key.keyName),\(key.count)"
        }
        
        return content
    }
}

// 修改统计行组件样式
struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
                .font(.title2)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
                .font(.title3)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// 导出数据模型
struct ExportDataModel: Codable {
    let timeRange: String
    let exportDate: Date
    let startDate: Date
    let endDate: Date
    let statistics: StatisticsData
    let keyFrequency: [KeyFrequencyData]
}

struct StatisticsData: Codable {
    let totalKeyCount: Int
    let uniqueKeyCount: Int
    let mostUsedKey: String
}

struct KeyFrequencyData: Codable {
    let keyCode: Int
    let keyName: String
    let count: Int
}

// 确保 UTType 扩展可用
extension UTType {
    static var json: UTType {
        UTType.json
    }
    
    static var commaSeparatedText: UTType {
        UTType("public.comma-separated-values-text") ?? .plainText
    }
}
