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
        
        // 数据管理子菜单
        let dataMenu = NSMenu()
        let dataMenuItem = NSMenuItem()
        dataMenuItem.title = "数据管理"
        menu.addItem(dataMenuItem)
        menu.setSubmenu(dataMenu, for: dataMenuItem)
        
        // 添加数据管理选项
        dataMenu.addItem(NSMenuItem(title: "导出数据", action: #selector(showExportSheet), keyEquivalent: ""))
        dataMenu.addItem(NSMenuItem(title: "导入数据", action: #selector(importData), keyEquivalent: ""))
        dataMenu.addItem(NSMenuItem(title: "清除数据", action: #selector(showClearDataAlert), keyEquivalent: ""))
        
        // 设置子菜单
        let settingsMenu = NSMenu()
        let settingsMenuItem = NSMenuItem()
        settingsMenuItem.title = "设置"
        menu.addItem(settingsMenuItem)
        menu.setSubmenu(settingsMenu, for: settingsMenuItem)
        
        // 添加设置选项
        let autoLaunchItem = NSMenuItem(title: "开机自启动", action: #selector(toggleAutoLaunch), keyEquivalent: "")
        autoLaunchItem.state = LaunchManager.shared.isAutoLaunchEnabled ? .on : .off
        settingsMenu.addItem(autoLaunchItem)
        
        // 备份设置子菜单
        let backupMenu = NSMenu()
        let backupMenuItem = NSMenuItem()
        backupMenuItem.title = "备份设置"
        settingsMenu.addItem(backupMenuItem)
        settingsMenu.setSubmenu(backupMenu, for: backupMenuItem)
        
        backupMenu.addItem(NSMenuItem(title: "启用自动备份", action: #selector(toggleAutoBackup), keyEquivalent: ""))
        backupMenu.addItem(NSMenuItem(title: "每天备份", action: #selector(setDailyBackup), keyEquivalent: ""))
        backupMenu.addItem(NSMenuItem(title: "每三天备份", action: #selector(setThreeDayBackup), keyEquivalent: ""))
        backupMenu.addItem(NSMenuItem(title: "每周备份", action: #selector(setWeeklyBackup), keyEquivalent: ""))
        
        // 主题设置子菜单
        let themeMenu = NSMenu()
        let themeMenuItem = NSMenuItem()
        themeMenuItem.title = "主题设置"
        settingsMenu.addItem(themeMenuItem)
        settingsMenu.setSubmenu(themeMenu, for: themeMenuItem)
        
        themeMenu.addItem(NSMenuItem(title: "默认主题", action: #selector(setDefaultTheme), keyEquivalent: ""))
        themeMenu.addItem(NSMenuItem(title: "海洋主题", action: #selector(setOceanTheme), keyEquivalent: ""))
        themeMenu.addItem(NSMenuItem(title: "森林主题", action: #selector(setForestTheme), keyEquivalent: ""))
        themeMenu.addItem(NSMenuItem(title: "日落主题", action: #selector(setSunsetTheme), keyEquivalent: ""))
        
        // 语言设置子菜单
        let languageMenu = NSMenu()
        let languageMenuItem = NSMenuItem()
        languageMenuItem.title = "语言设置"
        settingsMenu.addItem(languageMenuItem)
        settingsMenu.setSubmenu(languageMenu, for: languageMenuItem)
        
        languageMenu.addItem(NSMenuItem(title: "简体中文", action: #selector(setSimplifiedChinese), keyEquivalent: ""))
        languageMenu.addItem(NSMenuItem(title: "English", action: #selector(setEnglish), keyEquivalent: ""))
        languageMenu.addItem(NSMenuItem(title: "日本語", action: #selector(setJapanese), keyEquivalent: ""))
        languageMenu.addItem(NSMenuItem(title: "繁體中文", action: #selector(setTraditionalChinese), keyEquivalent: ""))
        languageMenu.addItem(NSMenuItem(title: "한국어", action: #selector(setKorean), keyEquivalent: ""))
        
        // 字体设置子菜单
        let fontMenu = NSMenu()
        let fontMenuItem = NSMenuItem()
        fontMenuItem.title = "字体设置"
        settingsMenu.addItem(fontMenuItem)
        settingsMenu.setSubmenu(fontMenu, for: fontMenuItem)
        
        fontMenu.addItem(NSMenuItem(title: "System Default", action: #selector(setSystemFont), keyEquivalent: ""))
        fontMenu.addItem(NSMenuItem(title: "Monaco", action: #selector(setMonacoFont), keyEquivalent: ""))
        fontMenu.addItem(NSMenuItem(title: "Microsoft YaHei", action: #selector(setYaheiFont), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 重置设置选项
        menu.addItem(NSMenuItem(title: LanguageManager.shared.localizedString("Reset All Settings"), 
                               action: #selector(showResetAlert), 
                               keyEquivalent: ""))
        
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
    }

    // 备份设置相关方法
    @objc private func toggleAutoBackup() {
        BackupManager.shared.isBackupEnabled.toggle()
    }

    @objc private func setDailyBackup() {
        BackupManager.shared.backupInterval = 1
    }

    @objc private func setThreeDayBackup() {
        BackupManager.shared.backupInterval = 3
    }

    @objc private func setWeeklyBackup() {
        BackupManager.shared.backupInterval = 7
    }

    // 主题设置相关方法
    @objc private func setDefaultTheme() {
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"), 
            object: nil, 
            userInfo: ["theme": "default"]
        )
    }

    @objc private func setOceanTheme() {
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"), 
            object: nil, 
            userInfo: ["theme": "ocean"]
        )
    }

    @objc private func setForestTheme() {
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"), 
            object: nil, 
            userInfo: ["theme": "forest"]
        )
    }

    @objc private func setSunsetTheme() {
        NotificationCenter.default.post(
            name: Notification.Name("changeTheme"), 
            object: nil, 
            userInfo: ["theme": "sunset"]
        )
    }

    // 语言设置相关方法
    @objc private func setSimplifiedChinese() {
        LanguageManager.shared.setLanguage(.simplifiedChinese)
    }

    @objc private func setEnglish() {
        LanguageManager.shared.setLanguage(.english)
    }

    @objc private func setJapanese() {
        LanguageManager.shared.setLanguage(.japanese)
    }

    @objc private func setTraditionalChinese() {
        LanguageManager.shared.setLanguage(.traditionalChinese)
    }

    @objc private func setKorean() {
        LanguageManager.shared.setLanguage(.korean)
    }

    // 字体设置相关方法
    @objc private func setSystemFont() {
        FontManager.shared.currentFont = "System Default"
    }

    @objc private func setMonacoFont() {
        FontManager.shared.currentFont = "Monaco"
    }

    @objc private func setYaheiFont() {
        FontManager.shared.currentFont = "Microsoft YaHei"
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
        
        // 6. 发送通知以显示重置成功提示
        NotificationCenter.default.post(name: Notification.Name("resetAllSettings"), object: nil)
        
        // 7. 更新菜单项状态
        updateMenuItemStates()
    }

    // 添加更新菜单项状态的方法
    private func updateMenuItemStates() {
        if let menu = statusBarItem.menu {
            // 更新自启动状态
            if let settingsMenu = menu.item(withTitle: "设置")?.submenu,
               let autoLaunchItem = settingsMenu.item(withTitle: "开机自启动") {
                autoLaunchItem.state = LaunchManager.shared.isAutoLaunchEnabled ? .on : .off
            }
            
            // 更新备份设置状态
            if let settingsMenu = menu.item(withTitle: "设置")?.submenu,
               let backupMenu = settingsMenu.item(withTitle: "备份设置")?.submenu,
               let autoBackupItem = backupMenu.item(withTitle: "启用自动备份") {
                autoBackupItem.state = BackupManager.shared.isBackupEnabled ? .on : .off
            }
        }
    }
}
