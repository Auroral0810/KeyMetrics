import SwiftUI
import AlertToast

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @State private var showExportSuccess = false
    @State private var showClearAlert = false
    @State private var autoStart = true
    @State private var showNotification = true
    @State private var backupInterval = 1 // 天
    @State private var keySoundEnabled = false
    @State private var selectedLanguage = "简体中文"
    @State private var selectedFont = "系统默认"
    
    let languages = ["简体中文", "English", "日本語"]
    let fonts = ["系统默认", "SF Pro", "Helvetica Neue", "Monaco"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 常规设置
                SettingSection(title: "常规", icon: "gear") {
                    SettingToggleRow(title: "开机自启动", isOn: $autoStart)
                    SettingToggleRow(title: "显示通知", isOn: $showNotification)
                    SettingPickerRow(title: "语言", selection: $selectedLanguage, options: languages)
                    SettingPickerRow(title: "字体", selection: $selectedFont, options: fonts)
                }
                
                // 外观设置
                SettingSection(title: "外观", icon: "paintbrush.fill") {
                    SettingToggleRow(title: "深色模式", isOn: $themeManager.isDarkMode)
                    ColorThemeSelector()
                }
                
                // 性能设置
                SettingSection(title: "性能", icon: "speedometer") {
                    SettingToggleRow(title: "后台统计", isOn: .constant(true))
                    SettingToggleRow(title: "按键音效", isOn: $keySoundEnabled)
                    SettingSliderRow(title: "历史记录保留", value: .constant(30), range: 7...90, unit: "天")
                }
                
                // 数据管理
                SettingSection(title: "数据管理", icon: "externaldrive.fill") {
                    VStack(spacing: 16) {
                        // 备份设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自动备份")
                                .foregroundColor(.gray)
                            HStack {
                                Picker("间隔", selection: $backupInterval) {
                                    Text("每天").tag(1)
                                    Text("每3天").tag(3)
                                    Text("每周").tag(7)
                                }
                                .pickerStyle(.segmented)
                                
                                Toggle("", isOn: .constant(true))
                                    .labelsHidden()
                            }
                        }
                        
                        // 数据操作按钮
                        HStack(spacing: 16) {
                            DataButton(
                                title: "导出数据",
                                icon: "square.and.arrow.up.fill",
                                color: .blue
                            ) {
                                exportData()
                            }
                            
                            DataButton(
                                title: "导入数据",
                                icon: "square.and.arrow.down.fill",
                                color: .green
                            ) {
                                // TODO: 实现导入逻辑
                            }
                            
                            DataButton(
                                title: "清除数据",
                                icon: "trash.fill",
                                color: .red
                            ) {
                                showClearAlert = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 高级设置
                SettingSection(title: "高级", icon: "wrench.and.screwdriver.fill") {
                    SettingToggleRow(title: "开发者模式", isOn: .constant(false))
                    SettingButton(title: "导出日志", icon: "doc.text.fill") {
                        // TODO: 实现日志导出
                    }
                    SettingButton(title: "重置所有设置", icon: "arrow.counterclockwise") {
                        // TODO: 实现重置逻辑
                    }
                }
            }
            .padding(20)
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .alert("确认清除", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) { clearData() }
        } message: {
            Text("此操作将清除所有数据且无法恢复，是否继续？")
        }
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("确定", role: .cancel) { }
        }
    }
    
    private func exportData() {
        // TODO: 实现导出逻辑
        showExportSuccess = true
    }
    
    private func clearData() {
        // 清空所有统计数据
        keyboardMonitor.keyStats = KeyStats()
        UserDefaults.standard.removeObject(forKey: "keyStats")
        showClearAlert = false
    }
}

// MARK: - 辅助视图组件

struct SettingSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Label(title, systemImage: icon)
                    .font(.headline)
                content
            }
        }
    }
}

struct SettingToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SettingPickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
        }
    }
}

struct SettingSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))\(unit)")
            }
            Slider(value: $value, in: range)
        }
    }
}

struct SettingButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct DataButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }
}

struct ColorThemeSelector: View {
    @State private var selectedTheme = 0
    let themes = ["默认", "海洋", "森林", "日落"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("主题色")
                .foregroundColor(.gray)
            HStack(spacing: 12) {
                ForEach(0..<themes.count, id: \.self) { index in
                    Circle()
                        .fill(getThemeColor(index))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .strokeBorder(selectedTheme == index ? .blue : .clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedTheme = index
                        }
                }
            }
        }
    }
    
    private func getThemeColor(_ index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .cyan
        case 2: return .green
        case 3: return .orange
        default: return .blue
        }
    }
}