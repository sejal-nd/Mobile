//
//  SERResult.swift
//  Mobile
//
//  Created by Samuel Francis on 12/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

fileprivate func extractDouble(_ object: Any) throws -> Double {
    guard let string = object as? String, let double = Double(string) else {
        throw MapperError.convertibleError(value: object, type: Double.self)
    }
    
    return double
}

struct SERResult: Mappable, Equatable {
    let actualKWH: Double
    let baselineKWH: Double
    let eventStart: Date
    let eventEnd: Date
    let savingDollar: Double
    let savingKWH: Double
    
    init(map: Mapper) throws {
        try eventStart = map.from("eventStart", transformation: DateParser().extractDate)
        try eventEnd = map.from("eventEnd", transformation: DateParser().extractDate)
        
        actualKWH = map.optionalFrom("actualKWH", transformation: extractDouble) ?? 0
        baselineKWH = map.optionalFrom("baselineKWH", transformation: extractDouble) ?? 0
        savingDollar = map.optionalFrom("savingDollar", transformation: extractDouble) ?? 0
        savingKWH = map.optionalFrom("savingKWH", transformation: extractDouble) ?? 0
    }
}
