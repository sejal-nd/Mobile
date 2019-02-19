//
//  AccountDetailTestInits.swift
//  Mobile
//
//  Created by Sam Francis on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Mapper

protocol JSONEncodable {
    func toJSON() -> [String: Any?]
}

fileprivate extension Date {
    var apiString: String {
        return DateFormatter.yyyyMMddTHHmmssZZZZZFormatter.string(from: self)
    }
}

extension SERResult: JSONEncodable {
    init(actualKWH: Double = 0,
         baselineKWH: Double = 0,
         eventStart: Date = .now,
         eventEnd: Date? = nil,
         savingDollar: Double = 0,
         savingKWH: Double = 0) {
        
        if Environment.shared.environmentName != .aut {
            fatalError("init only available for tests")
        }
        
        let end = eventEnd ?? Calendar.opCo.date(byAdding: DateComponents(hour: 8), to: eventStart)!
        
        var map = [String: Any?]()
        map["actualKWH"] = String(actualKWH)
        map["baselineKWH"] = String(baselineKWH)
        map["eventStart"] = eventStart.apiString
        map["eventEnd"] = end.apiString
        map["savingDollar"] = String(savingDollar)
        map["savingKWH"] = String(savingKWH)
        self = SERResult.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "actualKWH" : String(actualKWH),
            "baselineKWH" : String(baselineKWH),
            "eventStart" : eventStart.apiString,
            "eventEnd" : eventEnd.apiString,
            "savingDollar" : String(savingDollar),
            "savingKWH" : String(savingKWH)
        ]
    }
}
