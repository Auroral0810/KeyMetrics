import Foundation
import SwiftUI
import Cocoa

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusBarItem: NSStatusItem!
    private var window: NSWindow?
    
    // 用于存储窗口大小的 UserDefaults 键
    private let windowFrameKey = "MainWindowFrame"
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupWindow()
        setupNotificationObservers()
        
        // 设置为代理应用模式
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupStatusBar() {
        // 创建状态栏项
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        // 创建主菜单
        let menu = NSMenu()
        
        // 添加打开主窗口选项
        let openMenuItem = NSMenuItem()
        openMenuItem.title = "打开主窗口"
        openMenuItem.action = #selector(openMainWindow)
        openMenuItem.target = self
        menu.addItem(openMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加数据管理选项（直接添加到主菜单）
        menu.addItem(NSMenuItem(title: "导出数据", action: #selector(showExportSheet), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "导入数据", action: #selector(importData), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "清除数据", action: #selector(showClearDataAlert), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加深色模式选项
        let darkModeItem = NSMenuItem(title: "深色模式", action: #selector(toggleDarkMode), keyEquivalent: "")
        darkModeItem.state = UserDefaults.standard.bool(forKey: "isDarkMode") ? .on : .off
        menu.addItem(darkModeItem)
        
        // 添加自启动选项
        let autoLaunchItem = NSMenuItem(title: "开机自启动", action: #selector(toggleAutoLaunch), keyEquivalent: "")
        autoLaunchItem.state = LaunchManager.shared.isAutoLaunchEnabled ? .on : .off
        menu.addItem(autoLaunchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 备份设置（作为一级菜单项）
        let backupMenuItem = NSMenuItem()
        backupMenuItem.title = "备份设置"
        let backupMenu = NSMenu()
        menu.addItem(backupMenuItem)
        menu.setSubmenu(backupMenu, for: backupMenuItem)
        
        // 添加自动备份开关
        let autoBackupItem = NSMenuItem(title: "启用自动备份", action: #selector(toggleAutoBackup), keyEquivalent: "")
        autoBackupItem.state = BackupManager.shared.isBackupEnabled ? .on : .off
        backupMenu.addItem(autoBackupItem)
        
        backupMenu.addItem(NSMenuItem.separator())
        
        // 添加备份间隔选项
        let dailyBackupItem = NSMenuItem(title: "每天备份", action: #selector(setDailyBackup), keyEquivalent: "")
        let threeDayBackupItem = NSMenuItem(title: "每三天备份", action: #selector(setThreeDayBackup), keyEquivalent: "")
        let weeklyBackupItem = NSMenuItem(title: "每周备份", action: #selector(setWeeklyBackup), keyEquivalent: "")
        
        if BackupManager.shared.isBackupEnabled {
            dailyBackupItem.state = BackupManager.shared.backupInterval == 1 ? .on : .off
            threeDayBackupItem.state = BackupManager.shared.backupInterval == 3 ? .on : .off
            weeklyBackupItem.state = BackupManager.shared.backupInterval == 7 ? .on : .off
        }
        
        backupMenu.addItem(dailyBackupItem)
        backupMenu.addItem(threeDayBackupItem)
        backupMenu.addItem(weeklyBackupItem)
        
        // 主题设置（作为一级菜单项）
        let themeMenuItem = NSMenuItem()
        themeMenuItem.title = "主题颜色"
        let themeMenu = NSMenu()
        menu.addItem(themeMenuItem)
        menu.setSubmenu(themeMenu, for: themeMenuItem)
        
        // 添加主题选项
        let defaultThemeItem = NSMenuItem(title: "默认主题", action: #selector(setDefaultTheme), keyEquivalent: "")
        let oceanThemeItem = NSMenuItem(title: "海洋主题", action: #selector(setOceanTheme), keyEquivalent: "")
        let forestThemeItem = NSMenuItem(title: "森林主题", action: #selector(setForestTheme), keyEquivalent: "")
        let sunsetThemeItem = NSMenuItem(title: "日落主题", action: #selector(setSunsetTheme), keyEquivalent: "")
        
        let currentTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? "default"
        defaultThemeItem.state = currentTheme == "default" ? .on : .off
        oceanThemeItem.state = currentTheme == "ocean" ? .on : .off
        forestThemeItem.state = currentTheme == "forest" ? .on : .off
        sunsetThemeItem.state = currentTheme == "sunset" ? .on : .off
        
        themeMenu.addItem(defaultThemeItem)
        themeMenu.addItem(oceanThemeItem)
        themeMenu.addItem(forestThemeItem)
        themeMenu.addItem(sunsetThemeItem)
        
        // 语言设置（作为一级菜单项）
        let languageMenuItem = NSMenuItem()
        languageMenuItem.title = "语言设置"
        let languageMenu = NSMenu()
        menu.addItem(languageMenuItem)
        menu.setSubmenu(languageMenu, for: languageMenuItem)
        
        // 添加语言选项
        let simplifiedChineseItem = NSMenuItem(title: "简体中文", action: #selector(setSimplifiedChinese), keyEquivalent: "")
        let englishItem = NSMenuItem(title: "English", action: #selector(setEnglish), keyEquivalent: "")
        let japaneseItem = NSMenuItem(title: "日本語", action: #selector(setJapanese), keyEquivalent: "")
        let traditionalChineseItem = NSMenuItem(title: "繁體中文", action: #selector(setTraditionalChinese), keyEquivalent: "")
        let koreanItem = NSMenuItem(title: "한국어", action: #selector(setKorean), keyEquivalent: "")
        
        simplifiedChineseItem.state = LanguageManager.shared.currentLanguage == .simplifiedChinese ? .on : .off
        englishItem.state = LanguageManager.shared.currentLanguage == .english ? .on : .off
        japaneseItem.state = LanguageManager.shared.currentLanguage == .japanese ? .on : .off
        traditionalChineseItem.state = LanguageManager.shared.currentLanguage == .traditionalChinese ? .on : .off
        koreanItem.state = LanguageManager.shared.currentLanguage == .korean ? .on : .off
        
        languageMenu.addItem(simplifiedChineseItem)
        languageMenu.addItem(englishItem)
        languageMenu.addItem(japaneseItem)
        languageMenu.addItem(traditionalChineseItem)
        languageMenu.addItem(koreanItem)
        
        // 字体设置（作为一级菜单项）
        let fontMenuItem = NSMenuItem()
        fontMenuItem.title = "字体设置"
        let fontMenu = NSMenu()
        menu.addItem(fontMenuItem)
        menu.setSubmenu(fontMenu, for: fontMenuItem)
        
        // 添加字体选项
        let fonts = ["System Default", "Monaco", "SimHei", "SimSun", "STHeiti", "STKaiti", "Microsoft YaHei", "Arial", "Georgia"]
        let fontActions: [Selector] = [#selector(setSystemFont), #selector(setMonacoFont), #selector(setSimHeiFont), 
                                     #selector(setSimSunFont), #selector(setSTHeitiFont), #selector(setSTKaitiFont), 
                                     #selector(setYaheiFont), #selector(setArialFont), #selector(setGeorgiaFont)]
        
        for (index, font) in fonts.enumerated() {
            let item = NSMenuItem(title: font, action: fontActions[index], keyEquivalent: "")
            item.state = FontManager.shared.currentFont == font ? .on : .off
            fontMenu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 重置设置选项
        menu.addItem(NSMenuItem(title: "重置所有设置", action: #selector(showResetAlert), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出选项
        menu.addItem(NSMenuItem(title: "完全退出", action: #selector(quitApp), keyEquivalent: "Q"))
        
        // 设置菜单
        self.statusBarItem.menu = menu
        
        // 设置状态栏按钮的图标
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "statusicon")
        }
    }
    
    private func setupWindow() {
        window = NSApplication.shared.windows.first
        window?.delegate = self
        window?.isReleasedWhenClosed = false
        
        // 恢复保存的窗口大小和位置
        if let savedFrame = UserDefaults.standard.string(forKey: windowFrameKey) {
            let frameComponents = savedFrame.split(separator: ",").compactMap { Double($0) }
            if frameComponents.count == 4 {
                let frame = NSRect(x: frameComponents[0],
                                 y: frameComponents[1],
                                 width: frameComponents[2],
                                 height: frameComponents[3])
                window?.setFrame(frame, display: true)
            }
        }
    }
    
    // 保存窗口大小和位置
    public func windowWillClose(_ notification: Notification) {
        if let frame = window?.frame {
            let frameString = "\(frame.origin.x),\(frame.origin.y),\(frame.size.width),\(frame.size.height)"
            UserDefaults.standard.set(frameString, forKey: windowFrameKey)
        }
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.makeKeyAndOrderFront(self)
        NSApp.setActivationPolicy(.regular)
        return true
    }
    
    @objc private func openMainWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.setActivationPolicy(.regular)
    }
    
    // 处理 Command+Q
    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // 如果是通过菜单的"完全退出"触发的，则允许退出
        if let quitReason = sender.currentEvent?.window?.title, quitReason == "完全退出" {
            return .terminateNow
        }
        
        // 如果是通过 Command+Q 触发的（通过检查按键事件）
        if let event = sender.currentEvent,
           event.type == .keyDown,
           event.keyCode == 12, // Q 键的键码
           event.modifierFlags.contains(.command) {
            // 只是隐藏窗口而不是退出
            window?.close()
            NSApp.setActivationPolicy(.accessory)
            return .terminateCancel
        }
        
        // 其他情况（如右键退出）允许退出
        // 清理资源
        cleanupAndQuit()
        return .terminateNow
    }
    
    // 完全退出应用的方法
    @objc private func quitApp() {
        // 设置窗口标题以标识退出来源
        if let event = NSApp.currentEvent?.window {
            event.title = "完全退出"
        }
        
        // 使用标准的应用程序终止方法
        cleanupAndQuit()
        NSApp.terminate(nil)
    }
    
    // 清理资源的方法
    private func cleanupAndQuit() {
        // 保存任何需要保存的数据
        if let frame = window?.frame {
            let frameString = "\(frame.origin.x),\(frame.origin.y),\(frame.size.width),\(frame.size.height)"
            UserDefaults.standard.set(frameString, forKey: windowFrameKey)
            UserDefaults.standard.synchronize()
        }
        
        // 关闭窗口
        window?.close()
        
        // 移除状态栏图标
        if let statusBar = statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBar)
            statusBarItem = nil
        }
        
        // 清除窗口引用
        window = nil
    }
    
    // 数据管理相关方法
    @objc private func showExportSheet() {
        NotificationCenter.default.post(name: Notification.Name("showExportSheet"), object: nil)
    }

    @objc private func importData() {
        NotificationCenter.default.post(name: Notification.Name("showImportDialog"), object: nil)
    }

    @objc private func showClearDataAlert() {
        NotificationCenter.default.post(name: Notification.Name("showClearDataAlert"), object: nil)
    }

    // 自启动设置
    @objc private func toggleAutoLaunch() {
        LaunchManager.shared.isAutoLaunchEnabled.toggle()
        NotificationCenter.default.post(name: Notification.Name("autoLaunchChanged"), object: nil)
    }

    // 备份设置相关方法
    @objc private func toggleAutoBackup() {
        BackupManager.shared.isBackupEnabled.toggle()
        NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
    }

    @objc private func setDailyBackup() {
        if BackupManager.shared.isBackupEnabled {
            BackupManager.shared.backupInterval = 1
            NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
        }
    }

    @objc private func setThreeDayBackup() {
        if BackupManager.shared.isBackupEnabled {
            BackupManager.shared.backupInterval = 3
            NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
        }
    }

    @objc private func setWeeklyBackup() {
        if BackupManager.shared.isBackupEnabled {
            BackupManager.shared.backupInterval = 7
            NotificationCenter.default.post(name: Notification.Name("backupSettingsChanged"), object: nil)
        }
    }

    // 主题设置相关方法
    @objc private func setDefaultTheme() {
        NotificationCenter.default.post(name: Notification.Name("changeTheme"), object: nil, userInfo: ["theme": "default"])
        UserDefaults.standard.set("default", forKey: "currentTheme")
        updateMenuItemStates()
    }

    @objc private func setOceanTheme() {
        NotificationCenter.default.post(name: Notification.Name("changeTheme"), object: nil, userInfo: ["theme": "ocean"])
        UserDefaults.standard.set("ocean", forKey: "currentTheme")
        updateMenuItemStates()
    }

    @objc private func setForestTheme() {
        NotificationCenter.default.post(name: Notification.Name("changeTheme"), object: nil, userInfo: ["theme": "forest"])
        UserDefaults.standard.set("forest", forKey: "currentTheme")
        updateMenuItemStates()
    }

    @objc private func setSunsetTheme() {
        NotificationCenter.default.post(name: Notification.Name("changeTheme"), object: nil, userInfo: ["theme": "sunset"])
        UserDefaults.standard.set("sunset", forKey: "currentTheme")
        updateMenuItemStates()
    }

    // 语言设置相关方法
    @objc private func setSimplifiedChinese() {
        LanguageManager.shared.setLanguage(.simplifiedChinese)
        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
    }

    @objc private func setEnglish() {
        LanguageManager.shared.setLanguage(.english)
        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
    }

    @objc private func setJapanese() {
        LanguageManager.shared.setLanguage(.japanese)
        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
    }

    @objc private func setTraditionalChinese() {
        LanguageManager.shared.setLanguage(.traditionalChinese)
        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
    }

    @objc private func setKorean() {
        LanguageManager.shared.setLanguage(.korean)
        NotificationCenter.default.post(name: Notification.Name("languageChanged"), object: nil)
    }

    // 字体设置相关方法
    @objc private func setSystemFont() {
        FontManager.shared.currentFont = "System Default"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setMonacoFont() {
        FontManager.shared.currentFont = "Monaco"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setSimHeiFont() {
        FontManager.shared.currentFont = "SimHei"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setSimSunFont() {
        FontManager.shared.currentFont = "SimSun"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setSTHeitiFont() {
        FontManager.shared.currentFont = "STHeiti"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setSTKaitiFont() {
        FontManager.shared.currentFont = "STKaiti"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setYaheiFont() {
        FontManager.shared.currentFont = "Microsoft YaHei"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setArialFont() {
        FontManager.shared.currentFont = "Arial"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    @objc private func setGeorgiaFont() {
        FontManager.shared.currentFont = "Georgia"
        NotificationCenter.default.post(name: Notification.Name("fontChanged"), object: nil)
    }

    // 重置设置
    @objc private func showResetAlert() {
        let alert = NSAlert()
        alert.messageText = LanguageManager.shared.localizedString("Confirm Reset")
        alert.informativeText = LanguageManager.shared.localizedString("Reset settings confirmation message")
        alert.alertStyle = .warning
        alert.addButton(withTitle: LanguageManager.shared.localizedString("Confirm"))
        alert.addButton(withTitle: LanguageManager.shared.localizedString("Cancel"))
        
        if alert.runModal() == .alertFirstButtonReturn {
            resetAllSettings()
        }
    }

    @objc private func resetAllSettings() {
        // 1. 设置开机自启动
        LaunchManager.shared.isAutoLaunchEnabled = true
        
        // 2. 设置语言为英文
        LanguageManager.shared.setLanguage(.english)
        
        // 3. 设置字体为系统默认
        FontManager.shared.currentFont = "System Default"
        
        // 4. 设置深色模式和默认主题
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"), 
            object: nil, 
            userInfo: [
                "theme": "default",
                "isDarkMode": true
            ]
        )
        
        // 5. 设置备份选项
        BackupManager.shared.isBackupEnabled = true
        BackupManager.shared.backupInterval = 1  // 每天备份
        // 7. 显示重置成功提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            let alert = NSAlert()
            alert.messageText = LanguageManager.shared.localizedString("Reset Success")
            alert.informativeText = LanguageManager.shared.localizedString("Settings have been reset to default")
            alert.alertStyle = .informational
            alert.addButton(withTitle: LanguageManager.shared.localizedString("OK"))
            alert.runModal()
        }
        // 7. 更新菜单项状态
        updateMenuItemStates()
    }

    // 添加更新菜单项状态的方法
    private func updateMenuItemStates() {
        if let menu = statusBarItem.menu {
            // 更新深色模式状态
            if let darkModeItem = menu.items.first(where: { $0.title == "深色模式" }) {
                darkModeItem.state = UserDefaults.standard.bool(forKey: "isDarkMode") ? .on : .off
            }
            
            // 更新自启动状态
            if let autoLaunchItem = menu.items.first(where: { $0.title == "开机自启动" }) {
                autoLaunchItem.state = LaunchManager.shared.isAutoLaunchEnabled ? .on : .off
            }
            
            // 更新备份设置状态
            if let backupMenu = menu.items.first(where: { $0.title == "备份设置" })?.submenu {
                // 更新自动备份开关状态
                if let autoBackupItem = backupMenu.items.first(where: { $0.title == "启用自动备份" }) {
                    autoBackupItem.state = BackupManager.shared.isBackupEnabled ? .on : .off
                }
                
                // 更新备份间隔状态
                for item in backupMenu.items {
                    switch item.title {
                    case "每天备份":
                        item.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 1 ? .on : .off
                    case "每三天备份":
                        item.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 3 ? .on : .off
                    case "每周备份":
                        item.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 7 ? .on : .off
                    default:
                        break
                    }
                }
            }
            
            // 更新主题设置状态
            if let themeMenu = menu.items.first(where: { $0.title == "主题颜色" })?.submenu {
                let currentTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? "default"
                for item in themeMenu.items {
                    switch item.title {
                    case "默认主题":
                        item.state = currentTheme == "default" ? .on : .off
                    case "海洋主题":
                        item.state = currentTheme == "ocean" ? .on : .off
                    case "森林主题":
                        item.state = currentTheme == "forest" ? .on : .off
                    case "日落主题":
                        item.state = currentTheme == "sunset" ? .on : .off
                    default:
                        break
                    }
                }
            }
            
            // 更新语言设置状态
            if let languageMenu = menu.items.first(where: { $0.title == "语言设置" })?.submenu {
                for item in languageMenu.items {
                    switch item.title {
                    case "简体中文":
                        item.state = LanguageManager.shared.currentLanguage == .simplifiedChinese ? .on : .off
                    case "English":
                        item.state = LanguageManager.shared.currentLanguage == .english ? .on : .off
                    case "日本語":
                        item.state = LanguageManager.shared.currentLanguage == .japanese ? .on : .off
                    case "繁體中文":
                        item.state = LanguageManager.shared.currentLanguage == .traditionalChinese ? .on : .off
                    case "한국어":
                        item.state = LanguageManager.shared.currentLanguage == .korean ? .on : .off
                    default:
                        break
                    }
                }
            }
            
            // 更新字体设置状态
            if let fontMenu = menu.items.first(where: { $0.title == "字体设置" })?.submenu {
                for item in fontMenu.items {
                    item.state = FontManager.shared.currentFont == item.title ? .on : .off
                }
            }
        }
    }

    @objc private func toggleDarkMode() {
        let isDarkMode = !UserDefaults.standard.bool(forKey: "isDarkMode")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        
        // 获取当前主题
        let currentTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? "default"
        
        // 发送通知时包含完整的主题信息
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"),
            object: nil,
            userInfo: [
                "theme": currentTheme,
                "isDarkMode": isDarkMode
            ]
        )
        updateMenuItemStates()
    }
    
    private func setupNotificationObservers() {
        // 监听主题变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemeChange),
            name: Notification.Name("changeTheme"),
            object: nil
        )
        
        // 监听语言变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageChange),
            name: Notification.Name("languageChanged"),
            object: nil
        )
        
        // 监听字体变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFontChange),
            name: Notification.Name("fontChanged"),
            object: nil
        )
        
        // 监听自启动设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAutoLaunchChange),
            name: Notification.Name("autoLaunchChanged"),
            object: nil
        )
        
        // 监听备份设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackupSettingsChange),
            name: Notification.Name("backupSettingsChanged"),
            object: nil
        )
        
        // 监听重置设置
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResetSettings),
            name: Notification.Name("resetAllSettings"),
            object: nil
        )
    }
    
    @objc private func handleThemeChange(_ notification: Notification) {
        if let theme = notification.userInfo?["theme"] as? String {
            UserDefaults.standard.set(theme, forKey: "currentTheme")
        }
        if let isDarkMode = notification.userInfo?["isDarkMode"] as? Bool {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
        updateMenuItemStates()
    }
    
    @objc private func handleLanguageChange(_ notification: Notification) {
        updateMenuItemStates()
    }
    
    @objc private func handleFontChange(_ notification: Notification) {
        updateMenuItemStates()
    }
    
    @objc private func handleAutoLaunchChange(_ notification: Notification) {
        updateMenuItemStates()
    }
    
    @objc private func handleBackupSettingsChange(_ notification: Notification) {
        updateMenuItemStates()
    }
    
    @objc private func handleResetSettings(_ notification: Notification) {
        // 重置所有设置后更新菜单状态
        updateMenuItemStates()
    }
}
