import Foundation

enum LanguageType: String, CaseIterable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case traditionalChinese = "zh-Hant"
    case korean = "ko"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .traditionalChinese:
            return "繁體中文"
        case .korean:
            return "한국어"
        case .auto:
            return LanguageManager.shared.localizedString("Follow System")
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: LanguageType
    private var bundle: Bundle
    
    private init() {
        bundle = Bundle.main
        
        // 从 UserDefaults 读取已保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "language") {
            switch savedLanguage {
            case "zh-Hans":
                currentLanguage = .simplifiedChinese
            case "en":
                currentLanguage = .english
            case "ja":
                currentLanguage = .japanese
            case "zh-Hant":
                currentLanguage = .traditionalChinese
            case "ko":
                currentLanguage = .korean
            default:
                currentLanguage = .auto
            }
        } else {
            currentLanguage = .auto
        }
        
        // 如果是自动，则获取系统语言
        if currentLanguage == .auto {
            currentLanguage = getCurrentSystemLanguage()
        }
        
        // 设置 bundle
        updateBundle(for: currentLanguage)
    }
    
    private func getCurrentSystemLanguage() -> LanguageType {
        let preferredLang = NSLocale.preferredLanguages.first! as NSString
        let langStr = String(describing: preferredLang)
        
        switch langStr {
        case "en-US", "en-CN", "en":
            return .english
        case "zh-Hans-US", "zh-Hans-CN", "zh-Hans":
            return .simplifiedChinese
        case "zh-Hant-CN", "zh-TW", "zh-HK":
            return .traditionalChinese
        case "ja-JP", "ja":
            return .japanese
        case "ko-KR", "ko":
            return .korean
        default:
            return .english
        }
    }
    
    private func updateBundle(for language: LanguageType) {
        let type = language == .auto ? getCurrentSystemLanguage() : language
        if let path = Bundle.main.path(forResource: type.rawValue, ofType: "lproj") {
            bundle = Bundle(path: path) ?? Bundle.main
        }
    }
    
    func setLanguage(_ type: LanguageType) {
        currentLanguage = type
        
        if type == .auto {
            UserDefaults.standard.removeObject(forKey: "language")
            updateBundle(for: getCurrentSystemLanguage())
        } else {
            UserDefaults.standard.setValue(type.rawValue, forKey: "language")
            updateBundle(for: type)
        }
        
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("languageChanged"), object: nil)
    }
    
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }
} 