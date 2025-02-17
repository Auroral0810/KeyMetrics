import SwiftUI
import Charts

struct KeyFrequencyView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingExportSheet = false
    @State private var hoveredKey: String? = nil
    @State private var selectedChartType: ChartType = .donut
    
    enum TimeRange: String, CaseIterable {
        case day = "24小时"
        case week = "本周"
        case month = "本月"
        case all = "全部"
        
        var description: String {
            switch self {
            case .day: return "24小时内"
            case .week: return "本周"
            case .month: return "本月"
            case .all: return "全部时间"
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case donut = "环形图"
        case bar = "柱状图"
        case line = "趋势图"
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
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Picker("图表类型", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button(action: { showingExportSheet = true }) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
            .cornerRadius(12)
            
            HStack(spacing: 20) {
                // 左侧统计卡片，使用时间范围统计数据
                VStack(spacing: 16) {
                    StatCard(
                        title: "\(selectedTimeRange.rawValue)总按键",
                        value: "\(timeRangeStats.totalCount)",
                        icon: "keyboard",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "\(selectedTimeRange.rawValue)独特按键",
                        value: "\(timeRangeStats.uniqueKeys)",
                        icon: "number",
                        color: .green
                    )
                    
                    StatCard(
                        title: "\(selectedTimeRange.rawValue)最常用",
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
                    Text("TOP 10 按键")
                        .font(.headline)
                    
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
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// 排行榜行组件
struct RankingRow: View {
    let rank: Int
    let key: String
    let count: Int
    let total: Int
    let isHovered: Bool
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.system(.body, design: .rounded))
                .bold()
                .foregroundColor(.gray)
                .frame(width: 30)
            
            Text(key)
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Text(count > 0 ? "\(count)" : "-")
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

// 环形图组件
struct DonutChart: View {
    let data: ArraySlice<(key: String, count: Int)>
    @Binding var hoveredKey: String?
    private let totalKeyCount: Int
    
    private var chartData: [(key: String, count: Int)] {
        let top10Data = Array(data)
        let top10Total = top10Data.reduce(0) { $0 + $1.count }
        let othersCount = totalKeyCount - top10Total
        
        if othersCount > 0 {
            var combinedData = top10Data
            combinedData.append((key: "其他", count: othersCount))
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
        Chart {
            ForEach(chartData, id: \.key) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Key", item.key))
                .opacity(hoveredKey == nil || hoveredKey == item.key ? 1 : 0.3)
                .annotation(position: .overlay) {
                    if hoveredKey == item.key {
                        // 悬停时显示详细信息
                        VStack(spacing: 4) {
                            Text(item.key)
                                .font(.system(size: 12, weight: .bold))
                            Text("\(item.count)次")
                                .font(.system(size: 11))
                            Text(String(format: "%.1f%%", calculatePercentage(count: item.count)))
                                .font(.system(size: 11))
                        }
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    } else if item.key == "其他" {
                        // "其他"类别始终显示百分比
                        Text(String(format: "%.1f%%", calculatePercentage(count: item.count)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(height: 300)
        .chartLegend(position: .bottom)
    }
}

// 柱状图组件
struct BarChart: View {
    let data: ArraySlice<(key: String, count: Int)>
    @Binding var hoveredKey: String?
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.element.key) { index, item in
                BarMark(
                    x: .value("Key", item.key),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Key", item.key))
                .opacity(hoveredKey == nil || hoveredKey == item.key ? 1 : 0.3)
            }
        }
        .frame(height: 300)
        .chartLegend(position: .bottom)
    }
}

// 趋势图组件
struct LineChart: View {
    let data: ArraySlice<(key: String, count: Int)>
    @Binding var hoveredKey: String?
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.element.key) { index, item in
                // 添加线条
                LineMark(
                    x: .value("Index", index),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Key", item.key))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom) // 使用 catmullRom 插值方法
                
                // 添加点
                PointMark(
                    x: .value("Index", index),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(by: .value("Key", item.key))
                .symbolSize(30)
                
                // 添加数值标签
                if hoveredKey == item.key {
                    PointMark(
                        x: .value("Index", index),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("Key", item.key))
                    .annotation {
                        Text("\(item.count)")
                            .font(.caption)
                            .padding(4)
                            .background(.background.opacity(0.9))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .frame(height: 300)
        .chartLegend(position: .bottom)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: data.count))
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var exportFormat: ExportFormat = .json
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("导出格式", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }
                
                Section {
                    Button("导出数据") {
                        exportData()
                    }
                }
            }
            .navigationTitle("导出数据")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        // 实现数据导出逻辑
    }
}