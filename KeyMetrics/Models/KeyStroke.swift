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
    var totalDeleteCount: Int = 0  // 新增：删除键的总数
    var keyFrequency: [Int: Int]  // keyCode: count
    var hourlyStats: [Date: Int]  // hour: count
    var hourlyDeleteStats: [Date: Int] = [:]  // 新增：每小时删除键统计
    var dailyStats: [Date: Int]   // day: count
    var dailyKeyFrequency: [Date: [Int: Int]] = [:] // 新增字段
    init() {
        self.totalCount = 0
        self.keyFrequency = [:]
        self.hourlyStats = [:]
        self.dailyStats = [:]
    }
} 