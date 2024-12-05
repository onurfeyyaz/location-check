//
//  Item.swift
//  locationcheck
//
//  Created by Feyyaz ONUR on 5.12.2024.
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
