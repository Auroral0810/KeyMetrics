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
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            if !keyboardMonitor.isMonitoring {
                VStack {
                    Text(languageManager.localizedString("Accessibility Permission Required"))
                        .foregroundColor(.red)
                    Button(languageManager.localizedString("Grant Permission")) {
                        keyboardMonitor.startMonitoring()
                    }
                }
                .padding()
            }
            
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(languageManager.localizedString("Dashboard"), systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                KeyFrequencyView()
                    .tabItem {
                        Label(languageManager.localizedString("Key Analysis"), systemImage: "keyboard")
                    }
                    .tag(1)
                
                HistoryView()
                    .tabItem {
                        Label(languageManager.localizedString("History"), systemImage: "clock")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label(languageManager.localizedString("Settings"), systemImage: "gear")
                    }
                    .tag(3)
                
                AboutView()
                    .tabItem {
                        Label(languageManager.localizedString("About"), systemImage: "info.circle")
                    }
                    .tag(4)
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
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
}
