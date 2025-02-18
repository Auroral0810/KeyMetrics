import Foundation
import ServiceManagement

class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    
    @Published var isAutoLaunchEnabled: Bool {
        didSet {
            setAutoLaunch(enabled: isAutoLaunchEnabled)
            UserDefaults.standard.set(isAutoLaunchEnabled, forKey: "autoLaunch")
        }
    }
    
    private init() {
        self.isAutoLaunchEnabled = UserDefaults.standard.bool(forKey: "autoLaunch")
        // 检查当前是否已设置自启动
        checkAutoLaunchStatus()
    }
    
    private func checkAutoLaunchStatus() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            isAutoLaunchEnabled = SMAppService.mainApp.status == .enabled
        }
    }
    
    func setAutoLaunch(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    return  // 已经启用，无需重复设置
                }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set auto launch: \(error)")
        }
    }
} 