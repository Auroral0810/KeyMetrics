import SwiftUI
import AppKit

class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published var currentFont: String {
        didSet {
            UserDefaults.standard.set(currentFont, forKey: "selectedFont")
            // 发送字体改变通知
            NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
            updateSystemFont()
        }
    }
    
    init() {
        // 从 UserDefaults 加载上次选择的字体，如果没有则使用系统默认字体
        self.currentFont = UserDefaults.standard.string(forKey: "selectedFont") ?? "System Default"
        loadCustomFonts()
        updateSystemFont()
    }
    
    private func loadCustomFonts() {
        if let fontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            for url in fontURLs {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
    
    func getFont(size: CGFloat) -> Font {
        switch currentFont {
        case "System Default":
            return .system(size: size)
        case "Monaco":
            return .custom("Monaco", size: size)
        case "SimHei":
            return .custom("SimHei", size: size)
        case "SimSun":
            return .custom("SimSun", size: size)
        case "STHeiti":
            return .custom("STHeiti", size: size)
        case "STKaiti":
            return .custom("STKaiti", size: size)
        case "Microsoft YaHei":
            return .custom("Microsoft YaHei", size: size)
        case "Arial":
            return .custom("Arial", size: size)
        case "Georgia":
            return .custom("Georgia", size: size)
        default:
            return .system(size: size)
        }
    }
    
    private func updateSystemFont() {
        DispatchQueue.main.async {
            let size: CGFloat = 12
            let font: NSFont
            
            switch self.currentFont {
            case "Monaco":
                font = NSFont(name: "Monaco", size: size) ?? .systemFont(ofSize: size)
            case "SimHei":
                font = NSFont(name: "SimHei", size: size) ?? .systemFont(ofSize: size)
            case "SimSun":
                font = NSFont(name: "SimSun", size: size) ?? .systemFont(ofSize: size)
            case "STHeiti":
                font = NSFont(name: "STHeiti", size: size) ?? .systemFont(ofSize: size)
            case "STKaiti":
                font = NSFont(name: "STKaiti", size: size) ?? .systemFont(ofSize: size)
            case "Microsoft YaHei":
                font = NSFont(name: "Microsoft YaHei", size: size) ?? .systemFont(ofSize: size)
            case "Arial":
                font = NSFont(name: "Arial", size: size) ?? .systemFont(ofSize: size)
            case "Georgia":
                font = NSFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
            default:
                font = .systemFont(ofSize: size)
            }
            
            // 设置 NSTabView 的字体
            NSFont.systemFont(ofSize: size)
            let appearance = NSAppearance.current
            NSAppearance.current = appearance
            
            // 更新标签字体
            if let window = NSApplication.shared.windows.first {
                window.contentView?.needsDisplay = true
            }
        }
    }
} 