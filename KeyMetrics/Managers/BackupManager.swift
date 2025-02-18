import Foundation

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    @Published var isBackupEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBackupEnabled, forKey: "isBackupEnabled")
            if isBackupEnabled {
                scheduleNextBackup()
            }
        }
    }
    
    @Published var backupInterval: Int {
        didSet {
            UserDefaults.standard.set(backupInterval, forKey: "backupInterval")
            if isBackupEnabled {
                scheduleNextBackup()
            }
        }
    }
    
    private var lastBackupDate: Date {
        get { UserDefaults.standard.object(forKey: "lastBackupDate") as? Date ?? .distantPast }
        set { UserDefaults.standard.set(newValue, forKey: "lastBackupDate") }
    }
    
    init() {
        self.isBackupEnabled = UserDefaults.standard.bool(forKey: "isBackupEnabled")
        self.backupInterval = UserDefaults.standard.integer(forKey: "backupInterval")
        if backupInterval == 0 { self.backupInterval = 1 } // 默认每天
        
        checkAndPerformBackup()
        
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAndPerformBackup()
        }
    }
    
    func performBackup() {
        let fileManager = FileManager.default
        
        // 获取源文件路径（keystats.json）
        guard let sourceURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("keystats.json") else { return }
        
        // 确保源文件存在
        guard fileManager.fileExists(atPath: sourceURL.path) else { return }
        
        // 创建备份目录
        let backupDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KeyMetricsBackups")
        
        do {
            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            
            // 生成备份文件名（使用时间戳）
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let fileName = "keystats_\(dateFormatter.string(from: Date())).json"
            let backupURL = backupDirectory.appendingPathComponent(fileName)
            
            // 复制文件
            try fileManager.copyItem(at: sourceURL, to: backupURL)
            
            // 更新最后备份时间
            lastBackupDate = Date()
            
        } catch {
            print("Backup failed: \(error)")
        }
    }
    
    private func checkAndPerformBackup() {
        guard isBackupEnabled else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastBackupDate, to: now)
        
        if let days = components.day, days >= backupInterval {
            performBackup()
        }
    }
    
    private func scheduleNextBackup() {
        lastBackupDate = Date()
    }
} 