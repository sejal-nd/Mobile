//
//  NewAccountLookupResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewAccountLookupResult: Decodable {
    let accountNumber: String?
    let streetNumber: String?
    let unitNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "AccountNumber"
        case streetNumber = "StreetNumber"
        case unitNumber = "UnitNumber"
    }
}
