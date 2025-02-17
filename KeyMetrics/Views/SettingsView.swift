import SwiftUI
import AlertToast

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @State private var showExportSuccess = false
    @State private var showClearAlert = false
    @State private var showResetAlert = false
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
            VStack(spacing: 28) {
                // 常规设置
                SettingSection(title: "常规", icon: "gear") {
                    VStack(spacing: 16) {
                        SettingToggleRow(title: "开机自启动", isOn: $autoStart)
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            .padding(.horizontal, 4)
                        
                        Divider()
                            .background(ThemeManager.ThemeColors.divider(themeManager.isDarkMode))
                        
                        SettingPickerRow(title: "语言", selection: $selectedLanguage, options: languages)
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            .padding(.horizontal, 4)
                        
                        Divider()
                            .background(ThemeManager.ThemeColors.divider(themeManager.isDarkMode))
                        
                        SettingPickerRow(title: "字体", selection: $selectedFont, options: fonts)
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            .padding(.horizontal, 4)
                    }
                }
                
                // 外观设置
                SettingSection(title: "外观", icon: "paintbrush.fill") {
                    VStack(spacing: 16) {
                        SettingToggleRow(title: "深色模式", isOn: $themeManager.isDarkMode)
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            .padding(.horizontal, 4)
                        
                        Divider()
                            .background(ThemeManager.ThemeColors.divider(themeManager.isDarkMode))
                        
                        ThemePickerView()
                            .padding(.horizontal, 4)
                    }
                }
                
                // 数据管理
                SettingSection(title: "数据管理", icon: "externaldrive.fill") {
                    VStack(spacing: 24) {
                        // 备份设置
                        VStack(alignment: .leading, spacing: 12) {
                            Text("自动备份")
                                .font(.subheadline)
                                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                            
                            HStack(spacing: 20) {
                                Picker("间隔", selection: $backupInterval) {
                                    Text("每天").tag(1)
                                    Text("每3天").tag(3)
                                    Text("每周").tag(7)
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity)
                                .colorMultiply(themeManager.isDarkMode ? .white : .black)
                                
                                Toggle("", isOn: $showNotification)
                                    .labelsHidden()
                            }
                        }
                        
                        Divider()
                            .background(ThemeManager.ThemeColors.divider(themeManager.isDarkMode))
                        
                        // 数据操作按钮
                        HStack(spacing: 20) {
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
                    .padding(.horizontal, 12)
                }
                
                // 高级设置
                SettingSection(title: "高级", icon: "wrench.and.screwdriver.fill") {
                    Button(action: { showResetAlert = true }) {
                        HStack {
                            Label("重置所有设置", systemImage: "arrow.counterclockwise")
                                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(24)
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .alert("确认清除", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) { clearData() }
        } message: {
            Text("此操作将清除所有数据且无法恢复，是否继续？")
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
        }
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) { resetAllSettings() }
        } message: {
            Text("此操作将重置所有设置为默认值，是否继续？")
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
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
    
    private func resetAllSettings() {
        // 重置所有设置为默认值
        autoStart = true
        showNotification = true
        backupInterval = 1
        keySoundEnabled = false
        selectedLanguage = "简体中文"
        selectedFont = "系统默认"
        themeManager.isDarkMode = true
        
        // 保存默认设置到 UserDefaults
        UserDefaults.standard.set(true, forKey: "autoStart")
        UserDefaults.standard.set(true, forKey: "showNotification")
        UserDefaults.standard.set(1, forKey: "backupInterval")
        UserDefaults.standard.set(false, forKey: "keySoundEnabled")
        UserDefaults.standard.set("简体中文", forKey: "selectedLanguage")
        UserDefaults.standard.set("系统默认", forKey: "selectedFont")
        UserDefaults.standard.set(true, forKey: "isDarkMode")
    }
}

// MARK: - 辅助视图组件

struct SettingSection<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                content
            }
        }
        .groupBoxStyle(CustomGroupBoxStyle())
        .environmentObject(themeManager)
    }
}

struct CustomGroupBoxStyle: GroupBoxStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.isDarkMode 
                        ? Color(.darkGray).opacity(0.2) 
                        : Color(.lightGray).opacity(0.1))
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        themeManager.isDarkMode 
                            ? Color.gray.opacity(0.3) 
                            : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
    }
}

struct SettingToggleRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SettingPickerRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                        .tag(option)
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
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.callout)
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let themes = ["default", "ocean", "forest", "sunset"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("主题色")
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            HStack(spacing: 12) {
                ForEach(0..<themes.count, id: \.self) { index in
                    Circle()
                        .fill(getThemeColor(index))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .strokeBorder(themeManager.currentTheme == themes[index] ? .blue : .clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            themeManager.currentTheme = themes[index]
                            themeManager.applyTheme()
                        }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getThemeColor(_ index: Int) -> Color {
        ThemeManager.ThemeColors.chartColors[index % ThemeManager.ThemeColors.chartColors.count]
    }
}