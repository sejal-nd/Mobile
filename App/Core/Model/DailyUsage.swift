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
    var unit: String!
    var amount: Double
        
    init(map: Mapper) throws {
        try date = map.from("start", transformation: extractDate)
        try amount = map.from("usage")
    }

}

func extractDate(object: Any?) throws -> Date {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.calendar = .gmt
    dateFormatter.timeZone = .gmt
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    if let date = dateFormatter.date(from: dateString) {
        return date
    }
    
    throw MapperError.convertibleError(value: object, type: Date.self)
}

