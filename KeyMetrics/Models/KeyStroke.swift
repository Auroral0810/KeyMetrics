import Foundation

struct KeyStroke: Codable, Identifiable, Equatable {
    let id: UUID
    let keyCode: Int
    let timestamp: Date
    let character: String?
    
    init(keyCode: Int, character: String?) {
        self.id = UUID()
        self.keyCode = keyCode
        self.timestamp = Date()
        self.character = character
    }
    
    // 实现 Equatable
    static func == (lhs: KeyStroke, rhs: KeyStroke) -> Bool {
        lhs.id == rhs.id
    }
}

struct KeyStats: Codable {
    var totalCount: Int
    var totalDeleteCount: Int = 0
    var keyFrequency: [Int: Int]  // keyCode: count
    var hourlyStats: [Date: Int]  // hour: count
    var hourlyDeleteStats: [Date: Int] = [:]
    var dailyStats: [Date: Int]   // day: count
    var dailyKeyFrequency: [Date: [Int: Int]] = [:]  // 每天的按键频率
    
    // 新增：TOP10按键的数据结构
    struct KeyCount: Codable {
        let keyCode: Int
        let count: Int
    }
    
    // 新增：每天的详细统计数据
    struct DailyDetail: Codable {
        var totalCount: Int                // 总按键次数
        var uniqueKeysCount: Int          // 独特按键数量
        var keyFrequency: [Int: Int]      // 所有按键的频率
        var topTenKeys: [KeyCount]        // TOP10按键及其次数，使用 KeyCount 结构体
        
        init(totalCount: Int = 0, uniqueKeysCount: Int = 0, keyFrequency: [Int: Int] = [:]) {
            self.totalCount = totalCount
            self.uniqueKeysCount = uniqueKeysCount
            self.keyFrequency = keyFrequency
            self.topTenKeys = keyFrequency.sorted { $0.value > $1.value }
                .prefix(10)
                .map { KeyCount(keyCode: $0.key, count: $0.value) }
        }
    }
    
    var dailyDetails: [Date: DailyDetail] = [:]  // 每天的详细统计
    
    init() {
        self.totalCount = 0
        self.keyFrequency = [:]
        self.hourlyStats = [:]
        self.dailyStats = [:]
    }
    
    // 新增：更新每日详细统计的方法
    mutating func updateDailyDetail(for date: Date, keyCode: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        var detail = dailyDetails[startOfDay] ?? DailyDetail()
        detail.totalCount += 1
        detail.keyFrequency[keyCode, default: 0] += 1
        detail.uniqueKeysCount = detail.keyFrequency.keys.count
        detail.topTenKeys = detail.keyFrequency.sorted { $0.value > $1.value }
            .prefix(10)
            .map { KeyCount(keyCode: $0.key, count: $0.value) }
        
        dailyDetails[startOfDay] = detail
    }
    
    // 新增：获取指定日期的详细统计
    func getDailyDetail(for date: Date) -> DailyDetail? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return dailyDetails[startOfDay]
    }
} 