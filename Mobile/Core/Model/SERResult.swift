//
//  SERResult.swift
//  Mobile
//
//  Created by Samuel Francis on 12/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

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
        
        if let actualString: String = map.optionalFrom("actualKWH"), let doubleVal = Double(actualString) {
            actualKWH = doubleVal
        } else {
            actualKWH = 0
        }
        
        if let baselineString: String = map.optionalFrom("baselineKWH"), let doubleVal = Double(baselineString) {
            baselineKWH = doubleVal
        } else {
            baselineKWH = 0
        }
        
        if let savingDollarString: String = map.optionalFrom("savingDollar"), let doubleVal = Double(savingDollarString) {
            savingDollar = doubleVal
        } else {
            savingDollar = 0
        }
        
        if let savingKWHString: String = map.optionalFrom("savingKWH"), let doubleVal = Double(savingKWHString) {
            savingKWH = doubleVal
        } else {
            savingKWH = 0
        }
    }
    
    static func ==(lhs: SERResult, rhs: SERResult) -> Bool {
        return lhs.actualKWH == rhs.actualKWH &&
            lhs.baselineKWH == rhs.baselineKWH &&
            lhs.eventStart == rhs.eventStart &&
            lhs.eventEnd == rhs.eventEnd &&
            lhs.savingDollar == rhs.savingDollar &&
            lhs.savingKWH == rhs.savingKWH
    }
}
