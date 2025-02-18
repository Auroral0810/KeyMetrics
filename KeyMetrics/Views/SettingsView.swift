import SwiftUI
import AlertToast

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    @State private var showExportSuccess = false
    @State private var showClearAlert = false
    @State private var showResetAlert = false
    @State private var autoStart = true
    @State private var showNotification = true
    @State private var backupInterval = 1 // 天
    @State private var keySoundEnabled = false
    @State private var selectedLanguage = "简体中文"
    @State private var selectedFont = "System Default"
    @StateObject private var languageManagerState = LanguageManager.shared
    @State private var needsRefresh = false
    
    private let languages: [String] = LanguageType.allCases.map { $0.displayName }
    var fonts: [String] {
        [
            "System Default",
            "Monaco",
            "SimHei",
            "SimSun",
            "STHeiti",
            "STKaiti",
            "Microsoft YaHei",
            "Arial",
            "Georgia"
        ]
    }
    
    private func getLocalizedFont(_ font: String) -> String {
        return languageManager.localizedString(font)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 常规设置
                SettingSection(
                    title: languageManager.localizedString("General"),
                    icon: "gear"
                ) {
                    VStack(spacing: 16) {
                        SettingToggleRow(
                            title: languageManager.localizedString("Auto Start"),
                            isOn: $autoStart
                        )
                        .font(fontManager.getFont(size: 14))
                        
                        Divider()
                        
                        SettingPickerRow(
                            title: languageManager.localizedString("Language"),
                            selection: Binding(
                                get: { languageManager.currentLanguage.displayName },
                                set: { newValue in
                                    if let index = languages.firstIndex(of: newValue) {
                                        let type = LanguageType.allCases[index]
                                        languageManager.setLanguage(type)
                                        needsRefresh.toggle()
                                    }
                                }
                            ),
                            options: languages
                        )
                        .font(fontManager.getFont(size: 14))
                        
                        Divider()
                        
                        SettingPickerRow(
                            title: languageManager.localizedString("Font"),
                            selection: Binding(
                                get: { getLocalizedFont(fontManager.currentFont) },
                                set: { newValue in
                                    let actualFont = fonts.first { getLocalizedFont($0) == newValue } ?? "System Default"
                                    fontManager.currentFont = actualFont
                                    needsRefresh.toggle()
                                }
                            ),
                            options: fonts.map { getLocalizedFont($0) }
                        )
                        .font(fontManager.getFont(size: 14))
                    }
                }
                
                // 外观设置
                SettingSection(
                    title: languageManager.localizedString("Appearance"),
                    icon: "paintbrush.fill"
                ) {
                    VStack(spacing: 16) {
                        SettingToggleRow(
                            title: languageManager.localizedString("Dark Mode"),
                            isOn: $themeManager.isDarkMode
                        )
                        .font(fontManager.getFont(size: 14))
                        
                        Divider()
                        
                        ThemePickerView()
                            .padding(.horizontal, 4)
                    }
                }
                
                // 数据管理
                SettingSection(
                    title: languageManager.localizedString("Data Management"),
                    icon: "externaldrive.fill"
                ) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(languageManager.localizedString("Auto Backup"))
                                .font(fontManager.getFont(size: 14))
                                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
                            
                            HStack(spacing: 20) {
                                Picker(languageManager.localizedString("Interval"), selection: $backupInterval) {
                                    Text(languageManager.localizedString("Daily")).tag(1)
                                    Text(languageManager.localizedString("Every 3 Days")).tag(3)
                                    Text(languageManager.localizedString("Weekly")).tag(7)
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity)
                                .colorMultiply(themeManager.isDarkMode ? .white : .black)
                                
                                Toggle("", isOn: $showNotification)
                                    .labelsHidden()
                            }
                        }
                        
                        Divider()
                        
                        HStack(spacing: 20) {
                            DataButton(
                                title: languageManager.localizedString("Export Data"),
                                icon: "square.and.arrow.up.fill",
                                color: .blue
                            ) {
                                exportData()
                            }
                            
                            DataButton(
                                title: languageManager.localizedString("Import Data"),
                                icon: "square.and.arrow.down.fill",
                                color: .green
                            ) {
                                // TODO: 实现导入逻辑
                            }
                            
                            DataButton(
                                title: languageManager.localizedString("Clear Data"),
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
                SettingSection(
                    title: languageManager.localizedString("Advanced"),
                    icon: "wrench.and.screwdriver.fill"
                ) {
                    Button(action: { showResetAlert = true }) {
                        HStack {
                            Label(languageManager.localizedString("Reset All Settings"),
                                  systemImage: "arrow.counterclockwise")
                                .font(fontManager.getFont(size: 14))
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
        .alert(languageManager.localizedString("Confirm Clear"), isPresented: $showClearAlert) {
            Button(languageManager.localizedString("Cancel"), role: .cancel) { }
            Button(languageManager.localizedString("Confirm"), role: .destructive) { clearData() }
        } message: {
            Text(languageManager.localizedString("This action cannot be undone"))
                .font(fontManager.getFont(size: 14))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
        }
        .alert(languageManager.localizedString("Confirm Reset"), isPresented: $showResetAlert) {
            Button(languageManager.localizedString("Cancel"), role: .cancel) { }
            Button(languageManager.localizedString("Confirm"), role: .destructive) { resetAllSettings() }
        } message: {
            Text(languageManager.localizedString("Reset settings confirmation message"))
                .font(fontManager.getFont(size: 14))
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
        }
        .alert(languageManager.localizedString("Export Success"), isPresented: $showExportSuccess) {
            Button(languageManager.localizedString("OK"), role: .cancel) { }
        }
        .id(needsRefresh)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("languageChanged"))) { _ in
            needsRefresh.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("fontChanged"))) { _ in
            needsRefresh.toggle()
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
        selectedFont = "System Default"
        themeManager.isDarkMode = true
        
        // 保存默认设置到 UserDefaults
        UserDefaults.standard.set(true, forKey: "autoStart")
        UserDefaults.standard.set(true, forKey: "showNotification")
        UserDefaults.standard.set(1, forKey: "backupInterval")
        UserDefaults.standard.set(false, forKey: "keySoundEnabled")
        UserDefaults.standard.set("简体中文", forKey: "selectedLanguage")
        UserDefaults.standard.set("System Default", forKey: "selectedFont")
        UserDefaults.standard.set(true, forKey: "isDarkMode")
    }
}

// MARK: - 辅助视图组件

struct SettingSection<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var fontManager: FontManager
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
                    .font(fontManager.getFont(size: 16))
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
    @EnvironmentObject var fontManager: FontManager
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(fontManager.getFont(size: 14))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SettingPickerRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var fontManager: FontManager
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .font(fontManager.getFont(size: 14))
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .font(fontManager.getFont(size: 14))
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
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    
    let themes = [
        ("default", "Default Theme"),
        ("ocean", "Ocean Theme"),
        ("forest", "Forest Theme"),
        ("sunset", "Sunset Theme")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(languageManager.localizedString("Theme Color"))
                .font(fontManager.getFont(size: 14))
                .foregroundColor(ThemeManager.ThemeColors.secondaryText(themeManager.isDarkMode))
            
            HStack(spacing: 12) {
                ForEach(themes, id: \.0) { theme in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(getThemeColor(theme.0))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .strokeBorder(themeManager.currentTheme == theme.0 ? .blue : .clear, lineWidth: 2)
                            )
                        
                        Text(languageManager.localizedString(theme.1))
                            .font(fontManager.getFont(size: 12))
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                    .onTapGesture {
                        themeManager.currentTheme = theme.0
                        themeManager.applyTheme()
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getThemeColor(_ theme: String) -> Color {
        switch theme {
        case "default": return .blue
        case "ocean": return .cyan
        case "forest": return .green
        case "sunset": return .orange
        default: return .blue
        }
    }
}