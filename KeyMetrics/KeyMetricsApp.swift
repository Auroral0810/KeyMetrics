//
//  KeyMetricsApp.swift
//  KeyMetrics
//
//  Created by 俞云烽 on 2025/02/15.
//

import SwiftUI
import SwiftData

@main
struct KeyMetricsApp: App {
    @StateObject private var keyboardMonitor = KeyboardMonitor()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var fontManager = FontManager.shared
    
    init() {
        // 初始化语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "language") {
            switch savedLanguage {
            case "zh-Hans":
                LanguageManager.shared.setLanguage(.simplifiedChinese)
            case "en":
                LanguageManager.shared.setLanguage(.english)
            case "ja":
                LanguageManager.shared.setLanguage(.japanese)
            case "zh-Hant":
                LanguageManager.shared.setLanguage(.traditionalChinese)
            case "ko":
                LanguageManager.shared.setLanguage(.korean)
            default:
                LanguageManager.shared.setLanguage(.auto)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(keyboardMonitor)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environmentObject(fontManager)
                .onAppear {
                    keyboardMonitor.startMonitoring()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
