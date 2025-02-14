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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(keyboardMonitor)
                .environmentObject(themeManager)
                .onAppear {
                    keyboardMonitor.startMonitoring()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
