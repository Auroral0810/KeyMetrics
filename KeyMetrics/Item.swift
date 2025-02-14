//
//  Item.swift
//  KeyMetrics
//
//  Created by 俞云烽 on 2025/02/15.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
