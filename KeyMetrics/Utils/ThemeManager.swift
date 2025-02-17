import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true
    @Published var currentTheme: String = "default"
    
    func applyTheme() {
        // 保存用户偏好
        UserDefaults.standard.set(isDarkMode, forKey: "IsDarkMode")
        UserDefaults.standard.set(currentTheme, forKey: "CurrentTheme")
        UserDefaults.standard.synchronize()
        
        // 发送主题变更通知
        objectWillChange.send()
        
        // 更新系统外观
        if let window = NSApplication.shared.windows.first {
            window.appearance = isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }
    }
    
    struct ThemeColors {
        static func accent(_ isDark: Bool = true) -> Color {
            isDark ? Color(hex: "#4ECDC4") : Color(hex: "#45B7D1")
        }
        
        static func background(_ isDark: Bool) -> Color {
            isDark ? Color(hex: "#1A1A1A") : Color(hex: "#F5F5F5")
        }
        
        static func cardBackground(_ isDark: Bool) -> Color {
            isDark ? Color(.darkGray).opacity(0.2) : Color(.lightGray).opacity(0.1)
        }
        
        static func text(_ isDark: Bool) -> Color {
            isDark ? .white : .black
        }
        
        static func secondaryText(_ isDark: Bool) -> Color {
            isDark ? Color(.lightGray) : Color(.darkGray)
        }
        
        static func divider(_ isDark: Bool) -> Color {
            isDark ? Color(.darkGray) : Color(.lightGray)
        }
        
        static func border(_ isDark: Bool) -> Color {
            isDark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        }
        
        // 图表颜色
        static let chartColors: [Color] = [
            .blue,      // 默认
            .cyan,      // 海洋
            .green,     // 森林
            .orange     // 日落
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