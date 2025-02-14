import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    
    var body: some View {
        VStack(spacing: 20) {
            // 总计数据卡片
            HStack(spacing: 20) {
                StatCard(title: "总按键次数", value: "\(keyboardMonitor.keyStats.totalCount)")
                StatCard(title: "今日按键", value: "\(getTodayKeyCount())")
                StatCard(title: "本小时按键", value: "\(getCurrentHourKeyCount())")
            }
            .padding()
            
            // 今日活动图表
            VStack(alignment: .leading) {
                Text("今日活动")
                    .font(.headline)
                Chart {
                    ForEach(getHourlyData(), id: \.hour) { data in
                        BarMark(
                            x: .value("Hour", data.hour),
                            y: .value("Count", data.count)
                        )
                    }
                }
                .frame(height: 200)
            }
            .padding()
        }
    }
    
    private func getTodayKeyCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return keyboardMonitor.keyStats.dailyStats[today] ?? 0
    }
    
    private func getCurrentHourKeyCount() -> Int {
        let currentHour = Calendar.current.startOfHour(for: Date())
        return keyboardMonitor.keyStats.hourlyStats[currentHour] ?? 0
    }
    
    private func getHourlyData() -> [(hour: Int, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<24).map { hour in
            let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
            let count = keyboardMonitor.keyStats.hourlyStats[date] ?? 0
            return (hour: hour, count: count)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
} 