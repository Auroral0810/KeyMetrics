import Foundation

struct KeyStroke: Codable, Identifiable {
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
}

struct KeyStats: Codable {
    var totalCount: Int
    var keyFrequency: [Int: Int]  // keyCode: count
    var hourlyStats: [Date: Int]  // hour: count
    var dailyStats: [Date: Int]   // day: count
} 