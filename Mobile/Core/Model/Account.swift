//
//  Account.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

enum AccountType {
    case Residential
    case Commercial
}

struct Account: Mappable {
    let accountType: AccountType
    let accountNumber: String
    let address: String?
    let homeContactNumber: String
    
    init(map: Mapper) throws {
        try accountNumber = map.from("accountNumber")
        address = map.optionalFrom("address")
        
        accountType = .Residential
        homeContactNumber = "4106939286"
    }
}
