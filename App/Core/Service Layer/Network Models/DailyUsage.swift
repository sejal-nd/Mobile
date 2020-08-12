//
//  DailyUsage.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct DailyUsage: Decodable {
    var date: Date
    var amount: Double
    
    enum CodingKeys: String, CodingKey {
        case date = "start"
        case amount = "usage"
    }
}
