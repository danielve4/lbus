//
//  Item.swift
//  LBus
//
//  Created by Daniel Vega on 3/28/26.
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
