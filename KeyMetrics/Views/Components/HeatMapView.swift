import SwiftUI

struct HeatMapView: View {
    let data: [(hour: Int, intensity: Double)]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 24), spacing: 4) {
            ForEach(data, id: \.hour) { item in
                Rectangle()
                    .fill(getColor(for: item.intensity))
                    .frame(height: 30)
                    .overlay(
                        Text("\(item.hour)")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    )
                    .cornerRadius(4)
            }
        }
    }
    
    private func getColor(for intensity: Double) -> Color {
        let colors = ThemeManager.ThemeColors.chartColors
        let normalized = min(max(intensity, 0), 1)
        return colors[0].opacity(normalized)
    }
} 