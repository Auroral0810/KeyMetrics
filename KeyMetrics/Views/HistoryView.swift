import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @State private var selectedTimeRange: TimeRange = .week
    
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
                }
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