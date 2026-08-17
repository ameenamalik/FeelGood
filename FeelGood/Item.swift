//
//  Item.swift
//  FeelGood
//
//  Created by Ameena Malik on 2026-08-17.
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
