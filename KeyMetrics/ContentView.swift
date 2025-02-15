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
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            if !keyboardMonitor.isMonitoring {
                VStack {
                    Text("需要辅助功能权限才能统计键盘输入")
                        .foregroundColor(.red)
                    Button("授予权限") {
                        keyboardMonitor.startMonitoring()
                    }
                }
                .padding()
            }
            
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("仪表盘", systemImage: "chart.bar.fill")
                    }
                    .tag(0)
                
                KeyFrequencyView()
                    .tabItem {
                        Label("按键分析", systemImage: "keyboard")
                    }
                    .tag(1)
                
                HistoryView()
                    .tabItem {
                        Label("历史记录", systemImage: "clock")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("设置", systemImage: "gear")
                    }
                    .tag(3)
                
                AboutView()
                    .tabItem {
                        Label("关于我们", systemImage: "info.circle")
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
