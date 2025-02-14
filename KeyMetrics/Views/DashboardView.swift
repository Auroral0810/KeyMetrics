import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeRange: TimeRange = .day
    
    enum TimeRange: String, CaseIterable {
        case day = "24小时"
        case week = "本周"
        case month = "本月"
        case year = "全年"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部统计卡片
                HStack(spacing: 20) {
                    StatCardView(
                        title: "总按键次数",
                        value: "\(keyboardMonitor.keyStats.totalCount)",
                        icon: "keyboard",
                        color: ThemeManager.ThemeColors.chartColors[0]
                    )
                    
                    StatCardView(
                        title: "今日按键",
                        value: "\(getTodayKeyCount())",
                        icon: "clock",
                        color: ThemeManager.ThemeColors.chartColors[1]
                    )
                    
                    StatCardView(
                        title: "平均每小时",
                        value: "\(getAverageHourlyCount())",
                        icon: "chart.bar",
                        color: ThemeManager.ThemeColors.chartColors[2]
                    )
                }
                
                // 实时速度计
                SpeedMeterView(currentSpeed: getCurrentTypingSpeed())
                
                // 活动热力图
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("活动热力图")
                            .font(.headline)
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                        Spacer()
                        Picker("时间范围", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HeatMapView(data: getHeatMapData())
                        .environmentObject(themeManager)
                }
                .padding()
                .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                .cornerRadius(16)
                
                // 趋势图表
                VStack(alignment: .leading, spacing: 16) {
                    Text("击键趋势")
                        .font(.headline)
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    
                    Chart {
                        ForEach(getTrendData(), id: \.date) { item in
                            LineMark(
                                x: .value("时间", item.date),
                                y: .value("次数", item.count)
                            )
                            .foregroundStyle(ThemeManager.ThemeColors.chartColors[0])
                            
                            AreaMark(
                                x: .value("时间", item.date),
                                y: .value("次数", item.count)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [
                                        ThemeManager.ThemeColors.chartColors[0].opacity(0.3),
                                        ThemeManager.ThemeColors.chartColors[0].opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
                .cornerRadius(16)
            }
            .padding()
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
    }
    
    private func getTodayKeyCount() -> Int {
        let calendar = Calendar.current
        return keyboardMonitor.keyStats.dailyStats[calendar.startOfDay(for: Date())] ?? 0
    }
    
    private func getAverageHourlyCount() -> Int {
        let calendar = Calendar.current
        let todayCount = getTodayKeyCount()
        let currentHour = calendar.component(.hour, from: Date())
        return currentHour > 0 ? todayCount / currentHour : todayCount
    }
    
    private func getCurrentTypingSpeed() -> Double {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        let recentKeyStrokes = keyboardMonitor.keyStats.hourlyStats.filter { timestamp, _ in
            timestamp >= oneMinuteAgo && timestamp <= now
        }.values.reduce(0, +)
        
        return Double(recentKeyStrokes)
    }
    
    private func getHeatMapData() -> [(hour: Int, intensity: Double)] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<24).map { hour in
            guard let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) else {
                return (hour: hour, intensity: 0.0)
            }
            
            let count = keyboardMonitor.keyStats.hourlyStats[hourDate] ?? 0
            let maxCount = keyboardMonitor.keyStats.hourlyStats.values.max() ?? 1
            let intensity = Double(count) / Double(maxCount)
            
            return (hour: hour, intensity: intensity)
        }
    }
    
    private func getTrendData() -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        let dateRange: [Date]
        switch selectedTimeRange {
        case .day:
            dateRange = (0..<24).compactMap { hour in
                calendar.date(byAdding: .hour, value: -hour, to: now)
            }
        case .week:
            dateRange = (0..<7).compactMap { day in
                calendar.date(byAdding: .day, value: -day, to: now)
            }
        case .month:
            dateRange = (0..<30).compactMap { day in
                calendar.date(byAdding: .day, value: -day, to: now)
            }
        case .year:
            dateRange = (0..<12).compactMap { month in
                calendar.date(byAdding: .month, value: -month, to: now)
            }
        }
        
        return dateRange.map { date in
            let count: Int
            switch selectedTimeRange {
            case .day:
                count = keyboardMonitor.keyStats.hourlyStats[date] ?? 0
            case .week, .month, .year:
                let dayStart = calendar.startOfDay(for: date)
                count = keyboardMonitor.keyStats.dailyStats[dayStart] ?? 0
            }
            return (date: date, count: count)
        }.reversed()
    }
}

struct StatCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
        }
        .padding()
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

struct SpeedMeterView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentSpeed: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("实时击键速度")
                .font(.headline)
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            ZStack {
                Circle()
                    .stroke(
                        ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode).opacity(0.2),
                        lineWidth: 20
                    )
                
                Circle()
                    .trim(from: 0, to: min(currentSpeed / 300.0, 1.0))
                    .stroke(
                        ThemeManager.ThemeColors.chartColors[0],
                        style: StrokeStyle(
                            lineWidth: 20,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(currentSpeed))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    Text("次/分钟")
                        .font(.subheadline)
                        .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(ThemeManager.ThemeColors.cardBackground(themeManager.isDarkMode))
        .cornerRadius(16)
    }
} 