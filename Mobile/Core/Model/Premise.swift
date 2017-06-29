//
//  Premise.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct Premise: Mappable {
    let premiseNumber: String?
    let address: String?
    
    init(map: Mapper) throws {
        premiseNumber = map.optionalFrom("premiseNumber")
        address = map.optionalFrom("mainAddress.addressGeneral")
    }
}
