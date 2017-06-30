//
//  Premise.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct Premise: Mappable, Equatable, Hashable {
    let premiseNumber: String
    let address: String?
    
    init(map: Mapper) throws {
        try premiseNumber = map.from("premiseNumber")
        address = map.optionalFrom("mainAddress.addressGeneral")
    }
    
    // Equatable
    static func ==(lhs: Premise, rhs: Premise) -> Bool {
        return lhs.premiseNumber == rhs.premiseNumber
    }
    
    // Hashable
    var hashValue: Int {
        return premiseNumber.hash
    }
}
