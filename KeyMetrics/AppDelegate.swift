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
        openMenuItem.title = LanguageManager.shared.localizedString("Open Main Window")
        openMenuItem.action = #selector(openMainWindow)
        openMenuItem.target = self
        menu.addItem(openMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加数据管理选项
        menu.addItem(NSMenuItem(title: LanguageManager.shared.localizedString("Export Data"), action: #selector(showExportSheet), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: LanguageManager.shared.localizedString("Import Data"), action: #selector(importData), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: LanguageManager.shared.localizedString("Clear Data"), action: #selector(showClearDataAlert), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加深色模式选项
        let darkModeItem = NSMenuItem(title: LanguageManager.shared.localizedString("Dark Mode"), action: #selector(toggleDarkMode), keyEquivalent: "")
        darkModeItem.state = UserDefaults.standard.bool(forKey: "isDarkMode") ? .on : .off
        menu.addItem(darkModeItem)
        
        // 添加自启动选项
        let autoLaunchItem = NSMenuItem(title: LanguageManager.shared.localizedString("Auto Start"), action: #selector(toggleAutoLaunch), keyEquivalent: "")
        autoLaunchItem.state = LaunchManager.shared.isAutoLaunchEnabled ? .on : .off
        menu.addItem(autoLaunchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 备份设置
        let backupMenuItem = NSMenuItem()
        backupMenuItem.title = LanguageManager.shared.localizedString("Backup Settings")
        let backupMenu = NSMenu()
        menu.addItem(backupMenuItem)
        menu.setSubmenu(backupMenu, for: backupMenuItem)
        
        // 添加自动备份开关
        let autoBackupItem = NSMenuItem(title: LanguageManager.shared.localizedString("Auto Backup"), action: #selector(toggleAutoBackup), keyEquivalent: "")
        autoBackupItem.state = BackupManager.shared.isBackupEnabled ? .on : .off
        backupMenu.addItem(autoBackupItem)
        
        backupMenu.addItem(NSMenuItem.separator())
        
        // 添加备份间隔选项
        let dailyBackupItem = NSMenuItem(title: LanguageManager.shared.localizedString("Daily"), action: #selector(setDailyBackup), keyEquivalent: "")
        let threeDayBackupItem = NSMenuItem(title: LanguageManager.shared.localizedString("Every 3 Days"), action: #selector(setThreeDayBackup), keyEquivalent: "")
        let weeklyBackupItem = NSMenuItem(title: LanguageManager.shared.localizedString("Weekly"), action: #selector(setWeeklyBackup), keyEquivalent: "")
        
        dailyBackupItem.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 1 ? .on : .off
        threeDayBackupItem.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 3 ? .on : .off
        weeklyBackupItem.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 7 ? .on : .off
        
        backupMenu.addItem(dailyBackupItem)
        backupMenu.addItem(threeDayBackupItem)
        backupMenu.addItem(weeklyBackupItem)
        
        // 主题设置
        let themeMenuItem = NSMenuItem()
        themeMenuItem.title = LanguageManager.shared.localizedString("Theme")
        let themeMenu = NSMenu()
        menu.addItem(themeMenuItem)
        menu.setSubmenu(themeMenu, for: themeMenuItem)
        
        // 添加主题选项
        let defaultThemeItem = NSMenuItem(title: LanguageManager.shared.localizedString("Default Theme"), action: #selector(setDefaultTheme), keyEquivalent: "")
        let oceanThemeItem = NSMenuItem(title: LanguageManager.shared.localizedString("Ocean Theme"), action: #selector(setOceanTheme), keyEquivalent: "")
        let forestThemeItem = NSMenuItem(title: LanguageManager.shared.localizedString("Forest Theme"), action: #selector(setForestTheme), keyEquivalent: "")
        let sunsetThemeItem = NSMenuItem(title: LanguageManager.shared.localizedString("Sunset Theme"), action: #selector(setSunsetTheme), keyEquivalent: "")
        
        let currentTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? "default"
        defaultThemeItem.state = currentTheme == "default" ? .on : .off
        oceanThemeItem.state = currentTheme == "ocean" ? .on : .off
        forestThemeItem.state = currentTheme == "forest" ? .on : .off
        sunsetThemeItem.state = currentTheme == "sunset" ? .on : .off
        
        themeMenu.addItem(defaultThemeItem)
        themeMenu.addItem(oceanThemeItem)
        themeMenu.addItem(forestThemeItem)
        themeMenu.addItem(sunsetThemeItem)
        
        // 语言设置
        let languageMenuItem = NSMenuItem()
        languageMenuItem.title = LanguageManager.shared.localizedString("Language")
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
        
        // 字体设置
        let fontMenuItem = NSMenuItem()
        fontMenuItem.title = LanguageManager.shared.localizedString("Font")
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
        menu.addItem(NSMenuItem(title: LanguageManager.shared.localizedString("Reset All Settings"), action: #selector(showResetAlert), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出选项
        menu.addItem(NSMenuItem(title: LanguageManager.shared.localizedString("Quit"), action: #selector(quitApp), keyEquivalent: "Q"))
        
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
        // 先显示主窗口并切换到 SettingsView
        openMainWindow()
        // 发送切换到设置视图的通知
        NotificationCenter.default.post(name: Notification.Name("switchToSettings"), object: nil)
        // 延迟一小段时间后发送通知，确保窗口已经完全显示并切换到了设置视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: Notification.Name("showExportSheet"), object: nil)
        }
    }

    @objc private func importData() {
        // 先显示主窗口并切换到 SettingsView
        openMainWindow()
        // 发送切换到设置视图的通知
        NotificationCenter.default.post(name: Notification.Name("switchToSettings"), object: nil)
        // 延迟一小段时间后发送通知，确保窗口已经完全显示并切换到了设置视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: Notification.Name("showImportDialog"), object: nil)
        }
    }

    @objc private func showClearDataAlert() {
        // 先显示主窗口并切换到 SettingsView
        openMainWindow()
        // 发送切换到设置视图的通知
        NotificationCenter.default.post(name: Notification.Name("switchToSettings"), object: nil)
        // 延迟一小段时间后发送通知，确保窗口已经完全显示并切换到了设置视图
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: Notification.Name("showClearDataAlert"), object: nil)
        }
    }

    // 自启动设置
    @objc private func toggleAutoLaunch() {
        LaunchManager.shared.isAutoLaunchEnabled.toggle()
        NotificationCenter.default.post(name: Notification.Name("autoLaunchChanged"), object: nil)
    }

    // 备份设置相关方法
    @objc private func toggleAutoBackup() {
        BackupManager.shared.isBackupEnabled.toggle()
        updateMenuItemStates()  // 立即更新所有状态
    }

    @objc private func setDailyBackup() {
        if BackupManager.shared.isBackupEnabled {
            BackupManager.shared.backupInterval = 1
            updateMenuItemStates()
        }
    }

    @objc private func setThreeDayBackup() {
        if BackupManager.shared.isBackupEnabled {
            BackupManager.shared.backupInterval = 3
            updateMenuItemStates()
        }
    }

    @objc private func setWeeklyBackup() {
        if BackupManager.shared.isBackupEnabled {
            BackupManager.shared.backupInterval = 7
            updateMenuItemStates()
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
            if let darkModeItem = menu.items.first(where: { $0.action == #selector(toggleDarkMode) }) {
                darkModeItem.state = UserDefaults.standard.bool(forKey: "isDarkMode") ? .on : .off
            }
            
            // 更新自启动状态
            if let autoLaunchItem = menu.items.first(where: { $0.action == #selector(toggleAutoLaunch) }) {
                autoLaunchItem.state = LaunchManager.shared.isAutoLaunchEnabled ? .on : .off
            }
            
            // 更新备份设置状态
            if let backupMenu = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(toggleAutoBackup) }) ?? false })?.submenu {
                // 更新自动备份开关状态
                if let autoBackupItem = backupMenu.items.first(where: { $0.action == #selector(toggleAutoBackup) }) {
                    autoBackupItem.state = BackupManager.shared.isBackupEnabled ? .on : .off
                }
                
                // 更新备份间隔状态 - 只有在自动备份开启时才显示勾选状态
                for item in backupMenu.items {
                    switch item.action {
                    case #selector(setDailyBackup):
                        item.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 1 ? .on : .off
                    case #selector(setThreeDayBackup):
                        item.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 3 ? .on : .off
                    case #selector(setWeeklyBackup):
                        item.state = BackupManager.shared.isBackupEnabled && BackupManager.shared.backupInterval == 7 ? .on : .off
                    default:
                        break
                    }
                }
            }
            
            // 更新主题设置状态
            if let themeMenu = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(setDefaultTheme) }) ?? false })?.submenu {
                let currentTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? "default"
                for item in themeMenu.items {
                    switch item.action {
                    case #selector(setDefaultTheme):
                        item.state = currentTheme == "default" ? .on : .off
                    case #selector(setOceanTheme):
                        item.state = currentTheme == "ocean" ? .on : .off
                    case #selector(setForestTheme):
                        item.state = currentTheme == "forest" ? .on : .off
                    case #selector(setSunsetTheme):
                        item.state = currentTheme == "sunset" ? .on : .off
                    default:
                        break
                    }
                }
            }
            
            // 更新语言设置状态
            if let languageMenu = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(setSimplifiedChinese) }) ?? false })?.submenu {
                for item in languageMenu.items {
                    switch item.action {
                    case #selector(setSimplifiedChinese):
                        item.state = LanguageManager.shared.currentLanguage == .simplifiedChinese ? .on : .off
                    case #selector(setEnglish):
                        item.state = LanguageManager.shared.currentLanguage == .english ? .on : .off
                    case #selector(setJapanese):
                        item.state = LanguageManager.shared.currentLanguage == .japanese ? .on : .off
                    case #selector(setTraditionalChinese):
                        item.state = LanguageManager.shared.currentLanguage == .traditionalChinese ? .on : .off
                    case #selector(setKorean):
                        item.state = LanguageManager.shared.currentLanguage == .korean ? .on : .off
                    default:
                        break
                    }
                }
            }
            
            // 更新字体设置状态
            if let fontMenu = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(setSystemFont) }) ?? false })?.submenu {
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
        updateMenuItemTitles()
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

    private func updateMenuItemTitles() {
        if let menu = statusBarItem.menu {
            // 更新打开主窗口选项
            if let openItem = menu.items.first {
                openItem.title = LanguageManager.shared.localizedString("Open Main Window")
            }
            
            // 更新数据管理选项
            for item in menu.items {
                switch item.title {
                case _ where item.action == #selector(showExportSheet):
                    item.title = LanguageManager.shared.localizedString("Export Data")
                case _ where item.action == #selector(importData):
                    item.title = LanguageManager.shared.localizedString("Import Data")
                case _ where item.action == #selector(showClearDataAlert):
                    item.title = LanguageManager.shared.localizedString("Clear Data")
                case _ where item.action == #selector(toggleDarkMode):
                    item.title = LanguageManager.shared.localizedString("Dark Mode")
                case _ where item.action == #selector(toggleAutoLaunch):
                    item.title = LanguageManager.shared.localizedString("Auto Start")
                default:
                    break
                }
            }
            
            // 更新备份设置菜单
            if let backupItem = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(toggleAutoBackup) }) ?? false }) {
                backupItem.title = LanguageManager.shared.localizedString("Backup Settings")
                if let backupMenu = backupItem.submenu {
                    for item in backupMenu.items {
                        switch item.action {
                        case #selector(toggleAutoBackup):
                            item.title = LanguageManager.shared.localizedString("Auto Backup")
                        case #selector(setDailyBackup):
                            item.title = LanguageManager.shared.localizedString("Daily")
                        case #selector(setThreeDayBackup):
                            item.title = LanguageManager.shared.localizedString("Every 3 Days")
                        case #selector(setWeeklyBackup):
                            item.title = LanguageManager.shared.localizedString("Weekly")
                        default:
                            break
                        }
                    }
                }
            }
            
            // 更新主题设置菜单
            if let themeItem = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(setDefaultTheme) }) ?? false }) {
                themeItem.title = LanguageManager.shared.localizedString("Theme")
                if let themeMenu = themeItem.submenu {
                    for item in themeMenu.items {
                        switch item.action {
                        case #selector(setDefaultTheme):
                            item.title = LanguageManager.shared.localizedString("Default Theme")
                        case #selector(setOceanTheme):
                            item.title = LanguageManager.shared.localizedString("Ocean Theme")
                        case #selector(setForestTheme):
                            item.title = LanguageManager.shared.localizedString("Forest Theme")
                        case #selector(setSunsetTheme):
                            item.title = LanguageManager.shared.localizedString("Sunset Theme")
                        default:
                            break
                        }
                    }
                }
            }
            
            // 更新语言设置菜单标题
            if let languageItem = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(setSimplifiedChinese) }) ?? false }) {
                languageItem.title = LanguageManager.shared.localizedString("Language")
            }
            
            // 更新字体设置菜单标题
            if let fontItem = menu.items.first(where: { $0.submenu?.items.contains(where: { $0.action == #selector(setSystemFont) }) ?? false }) {
                fontItem.title = LanguageManager.shared.localizedString("Font")
            }
            
            // 更新重置和退出选项
            for item in menu.items {
                switch item.action {
                case #selector(showResetAlert):
                    item.title = LanguageManager.shared.localizedString("Reset All Settings")
                case #selector(quitApp):
                    item.title = LanguageManager.shared.localizedString("Quit")
                default:
                    break
                }
            }
        }
    }
}
