//
//  Item.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
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
