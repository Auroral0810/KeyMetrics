import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true
    
    struct ThemeColors {
        static func accent(_ isDark: Bool = true) -> Color {
            isDark ? Color(hex: "#4ECDC4") : Color(hex: "#45B7D1")
        }
        
        static func background(_ isDark: Bool = true) -> Color {
            isDark ? Color(hex: "#1A1A1A") : Color(hex: "#F5F5F5")
        }
        
        static func cardBackground(_ isDark: Bool = true) -> Color {
            isDark ? Color(hex: "#2D2D2D") : Color(hex: "#FFFFFF")
        }
        
        static func text(_ isDark: Bool = true) -> Color {
            isDark ? Color(hex: "#FFFFFF") : Color(hex: "#000000")
        }
        
        static func secondaryText(_ isDark: Bool = true) -> Color {
            isDark ? Color(hex: "#B0B0B0") : Color(hex: "#666666")
        }
        
        // 图表颜色
        static let chartColors: [Color] = [
            Color(hex: "#FF6B6B"),
            Color(hex: "#4ECDC4"),
            Color(hex: "#45B7D1"),
            Color(hex: "#96CEB4"),
            Color(hex: "#FFEEAD")
        ]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 