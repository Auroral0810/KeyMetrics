import SwiftUI
import Charts

struct KeyFrequencyView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingExportSheet = false
    
    enum TimeRange: String, CaseIterable {
        case day = "24小时"
        case week = "本周"
        case month = "本月"
        case all = "全部"
    }
    
    var sortedKeyFrequency: [(key: String, count: Int)] {
        keyboardMonitor.keyStats.keyFrequency
            .map { (keyboardMonitor.getKeyName(for: $0.key), $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部控制栏
                HStack {
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                    
                    Button(action: { showingExportSheet = true }) {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                }
                .padding()
                .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                .cornerRadius(16)
                
                // 键位分布环形图
                VStack(alignment: .leading, spacing: 16) {
                    Text("键位分布")
                        .font(.headline)
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    
                    Chart {
                        ForEach(sortedKeyFrequency.prefix(10), id: \.key) { item in
                            SectorMark(
                                angle: .value("Count", item.count),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Key", item.key))
                        }
                    }
                    .frame(height: 300)
                }
                .padding()
                .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                .cornerRadius(16)
                
                // 按键频率排行
                VStack(alignment: .leading, spacing: 16) {
                    Text("按键频率排行")
                        .font(.headline)
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    
                    VStack(spacing: 12) {
                        ForEach(sortedKeyFrequency.prefix(10), id: \.key) { item in
                            HStack {
                                Text(item.key)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                                    .frame(width: 80, alignment: .leading)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode).opacity(0.2))
                                        
                                        Rectangle()
                                            .fill(ThemeManager.ThemeColors.chartColors[0])
                                            .frame(width: getBarWidth(count: item.count, maxCount: sortedKeyFrequency[0].count, totalWidth: geometry.size.width))
                                    }
                                }
                                .frame(height: 24)
                                .cornerRadius(4)
                                
                                Text("\(item.count)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding()
                .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                .cornerRadius(16)
            }
            .padding()
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
    }
    
    private func getBarWidth(count: Int, maxCount: Int, totalWidth: CGFloat) -> CGFloat {
        let ratio = Double(count) / Double(maxCount)
        return totalWidth * CGFloat(ratio)
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