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
    let addressGeneral: String?
    let zipCode: String?
    let addressLine: Array<String>?
    
    init(map: Mapper) throws {
        try premiseNumber = map.from("premiseNumber")
        addressGeneral = map.optionalFrom("mainAddress.addressGeneral")
        addressLine = map.optionalFrom("mainAddress.addressLine")
        zipCode = map.optionalFrom("mainAddress.townDetail.code")
    }
    
    var addressLineString: String {
        guard let addressLineArray = addressLine else { return ""}
        return addressLineArray.joined(separator: ",")
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
