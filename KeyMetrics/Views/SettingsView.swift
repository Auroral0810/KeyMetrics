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
    @StateObject private var launchManager = LaunchManager.shared
    @State private var exportFormat: ExportFormat = .txt
    @State private var selectedTimeRange: TimeRange = .day
    @State private var isExporting = false
    @State private var showExportSheet = false
    @StateObject private var backupManager = BackupManager.shared
    @State private var showImportError = false
    @State private var showImportSuccess = false
    @State private var importErrorMessage = ""
    @State private var importSuccessMessage = ""
    @State private var showResetSuccess = false
    
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
                            isOn: Binding(
                                get: { launchManager.isAutoLaunchEnabled },
                                set: { newValue in
                                    launchManager.isAutoLaunchEnabled = newValue
                                    // 发送自启动设置变化通知
                                    NotificationCenter.default.post(name: Notification.Name("autoLaunchChanged"), object: nil)
                                }
                            )
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
                                        // 发送语言变化通知
                                        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
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
                                    // 发送字体变化通知
                                    NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
                                    needsRefresh.toggle()
                                }
                            ),
                            options: fonts.map { getLocalizedFont($0) }
                        )
                        .font(fontManager.getFont(size: 14))
                    }
                }
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                
                // 外观设置
                SettingSection(
                    title: languageManager.localizedString("Appearance"),
                    icon: "paintbrush.fill"
                ) {
                    VStack(spacing: 16) {
                        SettingToggleRow(
                            title: languageManager.localizedString("Dark Mode"),
                            isOn: Binding(
                                get: { themeManager.isDarkMode },
                                set: { newValue in
                                    themeManager.isDarkMode = newValue
                                    // 发送主题变化通知
                                    NotificationCenter.default.post(
                                        name: Notification.Name("changeTheme"),
                                        object: nil,
                                        userInfo: [
                                            "theme": themeManager.currentTheme,
                                            "isDarkMode": newValue
                                        ]
                                    )
                                }
                            )
                        )
                        .font(fontManager.getFont(size: 14))
                        
                        Divider()
                        
                        ThemePickerView()
                            .padding(.horizontal, 4)
                    }
                }
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                
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
                                Picker(languageManager.localizedString("Interval"), selection: Binding(
                                    get: { backupManager.backupInterval },
                                    set: { newValue in
                                        backupManager.backupInterval = newValue
                                        // 发送备份设置变化通知
                                        NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
                                    }
                                )) {
                                    Text(languageManager.localizedString("Daily")).tag(1)
                                    Text(languageManager.localizedString("Every 3 Days")).tag(3)
                                    Text(languageManager.localizedString("Weekly")).tag(7)
                                }
                                .pickerStyle(.segmented)
                                
                                Toggle("", isOn: Binding(
                                    get: { backupManager.isBackupEnabled },
                                    set: { newValue in
                                        backupManager.isBackupEnabled = newValue
                                        if newValue {
                                            backupManager.performBackup()
                                        }
                                        // 发送备份设置变化通知
                                        NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
                                    }
                                ))
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
                                showExportSheet = true
                            }
                            
                            DataButton(
                                title: languageManager.localizedString("Import Data"),
                                icon: "square.and.arrow.down.fill",
                                color: .green
                            ) {
                                importData()
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
                }
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                
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
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            }
            .padding(24)
        }
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: Notification.Name("changeTheme"),
                object: nil,
                queue: .main
            ) { notification in
                if let theme = notification.userInfo?["theme"] as? String {
                    themeManager.currentTheme = theme
                    if let isDarkMode = notification.userInfo?["isDarkMode"] as? Bool {
                        themeManager.isDarkMode = isDarkMode
                    }
                    themeManager.applyTheme()
                }
            }
            NotificationCenter.default.addObserver(
                forName: Notification.Name("resetAllSettings"),
                object: nil,
                queue: .main
            ) { _ in
                showResetSuccess = true
            }
        }
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
        .alert(
            languageManager.localizedString("Import Error"),
            isPresented: $showImportError,
            actions: {
                Button(languageManager.localizedString("OK"), role: .cancel) {}
            },
            message: {
                Text(importErrorMessage)
            }
        )
        .alert(
            languageManager.localizedString("Import Success"),
            isPresented: $showImportSuccess,
            actions: {
                Button(languageManager.localizedString("OK"), role: .cancel) {}
            },
            message: {
                Text(importSuccessMessage)
            }
        )
        .alert(languageManager.localizedString("Reset Success"), isPresented: $showResetSuccess) {
            Button(languageManager.localizedString("OK"), role: .cancel) { }
        } message: {
            Text(languageManager.localizedString("Settings have been reset to default"))
                .font(fontManager.getFont(size: 14))
        }
        .id(needsRefresh)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("languageChanged"))) { _ in
            needsRefresh.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("fontChanged"))) { _ in
            needsRefresh.toggle()
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSettingsView(
                exportFormat: $exportFormat,
                selectedTimeRange: $selectedTimeRange,
                isExporting: $isExporting,
                onExport: exportData
            )
        }
    }
    
    private func getStartDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .day:
            return calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return .distantPast
        }
    }
    
    private func prepareKeyFrequencyData(startDate: Date, endDate: Date) -> [KeyFrequencyData] {
        var frequencyMap: [Int: Int] = [:]
        
        for (date, keyFreq) in keyboardMonitor.keyStats.dailyKeyFrequency {
            if date >= startDate && date <= endDate {
                for (key, count) in keyFreq {
                    frequencyMap[key, default: 0] += count
                }
            }
        }
        
        return frequencyMap.map { key, count in
            KeyFrequencyData(
                keyCode: key,
                keyName: keyboardMonitor.getKeyName(for: key),
                count: count
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func exportData() {
        isExporting = true
        let startDate = getStartDate()
        let endDate = Date()
        
        let allKeyFrequency = prepareKeyFrequencyData(startDate: startDate, endDate: endDate)
        let top10Keys = Array(allKeyFrequency.prefix(10))
        
        let content: String
        if exportFormat == .json {
            content = generateJsonContent(
                timeRange: selectedTimeRange.description,
                stats: getTimeRangeStats(allKeyFrequency),
                top10: top10Keys,
                allKeys: allKeyFrequency
            )
        } else if exportFormat == .txt {
            content = generateTxtContent(
                timeRange: selectedTimeRange.description,
                stats: getTimeRangeStats(allKeyFrequency),
                top10: top10Keys,
                allKeys: allKeyFrequency
            )
        } else {
            content = generateCsvContent(
                timeRange: selectedTimeRange.description,
                stats: getTimeRangeStats(allKeyFrequency),
                top10: top10Keys,
                allKeys: allKeyFrequency
            )
        }
        
        do {
            // 生成文件名：时间戳_时间范围.扩展名
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let timeRangeStr = selectedTimeRange.rawValue.replacingOccurrences(of: " ", with: "_")
            let fileName = "keymetrics_\(timestamp)_\(timeRangeStr)"
            
            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
                .appendingPathExtension(exportFormat.rawValue.lowercased())
            
            try content.write(to: tempFile, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([tempFile])
            showExportSuccess = true
        } catch {
            print("Export failed: \(error)")
        }
        
        isExporting = false
        showExportSheet = false
    }
    
    private func getTimeRangeStats(_ data: [KeyFrequencyData]) -> (totalCount: Int, uniqueKeys: Int, mostUsedKey: String) {
        let totalCount = data.reduce(0) { $0 + $1.count }
        let uniqueKeys = data.count
        let mostUsedKey = data.first?.keyName ?? ""
        
        return (totalCount, uniqueKeys, mostUsedKey)
    }
    
    private func generateTxtContent(timeRange: String, stats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String),
                                  top10: [KeyFrequencyData], allKeys: [KeyFrequencyData]) -> String {
        var content = """
        \(languageManager.localizedString("Time Range")): \(timeRange)
        
        \(languageManager.localizedString("Statistics Summary")):
        \(languageManager.localizedString("Total Keys")): \(stats.totalCount)
        \(languageManager.localizedString("Unique Keys")): \(stats.uniqueKeys)
        \(languageManager.localizedString("Most Used Key")): \(stats.mostUsedKey)
        
        \(languageManager.localizedString("TOP 10 Keys Statistics")):
        """
        
        for (index, key) in top10.enumerated() {
            content += "\n\(index + 1). \(key.keyName): \(key.count) \(languageManager.localizedString("Times"))"
        }
        
        content += "\n\n\(languageManager.localizedString("All Keys Statistics")):"
        
        for key in allKeys {
            content += "\n\(key.keyName): \(key.count) \(languageManager.localizedString("Times"))"
        }
        
        return content
    }
    
    private func generateCsvContent(timeRange: String, stats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String),
                                  top10: [KeyFrequencyData], allKeys: [KeyFrequencyData]) -> String {
        var content = """
        \(languageManager.localizedString("Data Type")),\(languageManager.localizedString("Value"))
        \(languageManager.localizedString("Time Range")),\(timeRange)
        \(languageManager.localizedString("Total Keys")),\(stats.totalCount)
        \(languageManager.localizedString("Unique Keys")),\(stats.uniqueKeys)
        \(languageManager.localizedString("Most Used Key")),\(stats.mostUsedKey)
        
        \(languageManager.localizedString("TOP 10 Keys Statistics"))
        \(languageManager.localizedString("Rank")),\(languageManager.localizedString("Key")),\(languageManager.localizedString("Count"))
        """
        
        for (index, key) in top10.enumerated() {
            content += "\n\(index + 1),\(key.keyName),\(key.count)"
        }
        
        content += "\n\n\(languageManager.localizedString("All Keys Statistics"))"
        content += "\n\(languageManager.localizedString("Key")),\(languageManager.localizedString("Count"))"
        
        for key in allKeys {
            content += "\n\(key.keyName),\(key.count)"
        }
        
        return content
    }
    
    private func generateJsonContent(timeRange: String, stats: (totalCount: Int, uniqueKeys: Int, mostUsedKey: String),
                                   top10: [KeyFrequencyData], allKeys: [KeyFrequencyData]) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 创建一个函数来获取按键的可读名称
        func getReadableKeyName(_ keyCode: Int) -> String {
            return keyboardMonitor.getKeyName(for: keyCode)
        }
        
        // 转换按键频率数据为可读格式
        let readableKeyFrequency = Dictionary(uniqueKeysWithValues: allKeys.map { 
            (getReadableKeyName($0.keyCode), $0.count) 
        })
        
        // 转换 top10 数据为可读格式
        let readableTop10 = top10.map { key in
            [
                "keyName": getReadableKeyName(key.keyCode),
                "count": key.count
            ]
        }
        
        let jsonDict: [String: Any] = [
            "timeRange": timeRange,
            "statistics": [
                "totalCount": stats.totalCount,
                "uniqueKeysCount": stats.uniqueKeys,
                "mostUsedKey": getReadableKeyName(top10.first?.keyCode ?? 0)
            ],
            "top10Keys": readableTop10,
            "allKeys": readableKeyFrequency,
            "timestamp": timestamp,
            "date": Date().formatted(date: .complete, time: .complete)
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("JSON serialization failed: \(error)")
        }
        
        return "{}"
    }
    
    private func clearData() {
        // 清空所有统计数据
        keyboardMonitor.keyStats = KeyStats()
        UserDefaults.standard.removeObject(forKey: "keyStats")
        showClearAlert = false
    }
    
    private func resetAllSettings() {
        // 1. 设置开机自启动
        launchManager.isAutoLaunchEnabled = true
        NotificationCenter.default.post(name: Notification.Name("autoLaunchChanged"), object: nil)
        
        // 2. 设置语言为英文
        languageManager.setLanguage(.english)
        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
        
        // 3. 设置字体为系统默认
        fontManager.currentFont = "System Default"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
        
        // 4. 设置深色模式和默认主题
        themeManager.isDarkMode = true
        themeManager.currentTheme = "default"
        
        // 保存设置到 UserDefaults
        UserDefaults.standard.set(true, forKey: "isDarkMode")
        UserDefaults.standard.set("default", forKey: "currentTheme")
        
        // 发送主题变化通知，包含完整的主题信息
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"),
            object: nil,
            userInfo: [
                "theme": "default",
                "isDarkMode": true
            ]
        )
        themeManager.applyTheme()
        
        // 5. 设置备份选项
        backupManager.isBackupEnabled = true
        backupManager.backupInterval = 1  // 每天备份
        NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
        
        // 6. 发送重置设置通知
        NotificationCenter.default.post(name: Notification.Name("resetAllSettings"), object: nil)
        
        // 7. 显示重置成功提示
        showResetSuccess = true
    }
    
    private func showResetSuccessMessage(_ message: String) {
        showResetSuccess = true
    }
    
    private func importData() {
        let dialog = NSOpenPanel()
        dialog.title = languageManager.localizedString("Choose Backup File")
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["json"]
        
        if dialog.runModal() == .OK {
            guard let url = dialog.url else { return }
            
            do {
                let data = try Data(contentsOf: url)
                // 尝试解码数据以验证格式
                let decoder = JSONDecoder()
                let stats = try decoder.decode(KeyStats.self, from: data)
                
                // 如果解码成功，将文件复制到应用的 Documents 目录
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destURL = documentsURL.appendingPathComponent("keystats.json")
                
                // 如果目标文件已存在，先删除它
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                
                // 复制新文件
                try fileManager.copyItem(at: url, to: destURL)
                
                // 重新加载数据
                keyboardMonitor.loadStats()
                
                // 显示成功提示
                showImportSuccess = true
                importSuccessMessage = languageManager.localizedString("Data imported successfully")
                
            } catch {
                showImportError = true
                importErrorMessage = languageManager.localizedString("Invalid file format or corrupted data")
                print("Import failed: \(error)")
            }
        }
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
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
            
            Spacer()
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: { selection = option }) {
                        HStack {
                            Text(option)
                                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            if selection == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                        .font(.system(size: 12))
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .fixedSize()
            .colorMultiply(themeManager.isDarkMode ? .white : .black)
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

enum ExportFormat: String, CaseIterable {
    case txt = "TXT"
    case csv = "CSV"
    case json = "JSON"
}

enum TimeRange: String, CaseIterable {
    case day = "Last 24 Hours"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    case all = "All Time"
    
    var description: String {
        LanguageManager.shared.localizedString(self.rawValue)
    }
}

struct ExportSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var fontManager: FontManager
    
    @Binding var exportFormat: ExportFormat
    @Binding var selectedTimeRange: TimeRange
    @Binding var isExporting: Bool
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题区域
            HStack {
                Text(languageManager.localizedString("Export Data"))
                    .font(fontManager.getFont(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // 主要内容区域
            VStack(spacing: 24) {
                // 时间范围选择
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(languageManager.localizedString("Select Time Range"))
                            .font(fontManager.getFont(size: 14))
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                    
                    Picker(languageManager.localizedString("Time Range"), selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.description)
                                .font(fontManager.getFont(size: 12))
                                .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorMultiply(themeManager.isDarkMode ? .white : .black)
                }
                
                // 导出格式选择
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                        Text(languageManager.localizedString("Export Format"))
                            .font(fontManager.getFont(size: 14))
                            .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                    }
                    
                    Picker(languageManager.localizedString("Format"), selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                                .font(fontManager.getFont(size: 12))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
            .background(themeManager.isDarkMode ? ThemeManager.ThemeColors.cardBackground(true) : Color(.lightGray).opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // 底部按钮区域
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Text(languageManager.localizedString("Cancel"))
                        .font(fontManager.getFont(size: 12))
                        .foregroundColor(ThemeManager.ThemeColors.text(themeManager.isDarkMode))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                
                Button(action: onExport) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .colorMultiply(themeManager.isDarkMode ? .white : .black)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? languageManager.localizedString("Exporting...") : languageManager.localizedString("Export"))
                            .font(fontManager.getFont(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
            }
            .padding()
        }
        .frame(width: 500)
        .background(ThemeManager.ThemeColors.background(themeManager.isDarkMode))
    }
}
