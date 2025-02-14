import SwiftUI
import Charts

struct KeyFrequencyView: View {
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    
    var sortedKeyFrequency: [(key: String, count: Int)] {
        keyboardMonitor.keyStats.keyFrequency
            .map { (keyboardMonitor.getKeyName(for: $0.key), $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack {
            Text("按键频率统计")
                .font(.title)
                .padding()
            
            Chart {
                ForEach(sortedKeyFrequency.prefix(20), id: \.key) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Key", item.key)
                    )
                }
            }
            .frame(height: 400)
            .padding()
            
            List {
                ForEach(sortedKeyFrequency.prefix(30), id: \.key) { item in
                    HStack {
                        Text(item.key)
                            .frame(width: 100, alignment: .leading)
                        Text("\(item.count)")
                        ProgressView(value: Double(item.count), total: Double(sortedKeyFrequency.first?.count ?? 1))
                    }
                }
            }
        }
    }
} 