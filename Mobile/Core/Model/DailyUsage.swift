//
//  DailyUsage.swift
//  Mobile
//
//  Created by Marc Shilling on 11/5/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct DailyUsage: Mappable {
    var date: Date
    var usage: Double
    
    init(map: Mapper) throws {
        try date = map.from("start", transformation: DateParser().extractDate)
        try usage = map.from("usage")
    }
}
