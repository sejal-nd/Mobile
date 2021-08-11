//
//  RegistrationAccountLookup.swift
//  Mobile
//
//  Created by Cody Dillon on 8/19/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AccountResult: Decodable {
    let accountNumber: String?
    let customerID: String?
    let streetNumber: String?
    let unitNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "fullAccountNumber"
        case customerID = "customerID"
        case streetNumber = "street"
        case unitNumber = "unit"
    }
}
