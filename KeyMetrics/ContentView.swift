//
//  ContentView.swift
//  KeyMetrics
//
//  Created by 俞云烽 on 2025/02/15.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    @State private var selectedTab = 0
    @State private var needsRefresh = false

    var body: some View {
        VStack {
            if !keyboardMonitor.isMonitoring {
                VStack {
                    Text(languageManager.localizedString("Accessibility Permission Required"))
                        .foregroundColor(.red)
                        .font(fontManager.getFont(size: 14))
                    Button(languageManager.localizedString("Grant Permission")) {
                        keyboardMonitor.startMonitoring()
                    }
                    .font(fontManager.getFont(size: 14))
                }
                .padding()
            }
            
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text(languageManager.localizedString("Dashboard"))
                    }
                    .tag(0)
                
                KeyFrequencyView()
                    .tabItem {
                        Image(systemName: "keyboard")
                        Text(languageManager.localizedString("Key Analysis"))
                    }
                    .tag(1)
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock")
                        Text(languageManager.localizedString("History"))
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text(languageManager.localizedString("Settings"))
                    }
                    .tag(3)
                
                AboutView()
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text(languageManager.localizedString("About"))
                    }
                    .tag(4)
            }
            .id("\(fontManager.currentFont)_\(needsRefresh)")
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("fontChanged"))) { _ in
            needsRefresh.toggle()
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.contentView?.needsDisplay = true
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(KeyboardMonitor())
        .environmentObject(LanguageManager.shared)
        .environmentObject(FontManager.shared)
}
