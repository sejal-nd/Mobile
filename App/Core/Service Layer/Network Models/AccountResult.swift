//
//  RegistrationAccountLookup.swift
//  Mobile
//
//  Created by Cody Dillon on 8/19/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AccountResult: Decodable {
    let maskedAccountNumber: String?
    let fullAccountNumber: String?
    let customerID: String?
    let streetNumber: String?
    let unitNumber: String?
    let auid: String?
    var isResidential: Bool?
    
    var accountNumber: String? {
        if fullAccountNumber?.isEmpty == false {
            return fullAccountNumber
        } else {
            return maskedAccountNumber
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case maskedAccountNumber = "accountNumber"
        case fullAccountNumber = "fullAccountNumber"
        case customerID = "customerID"
        case streetNumber = "street"
        case unitNumber = "unit"
        case auid = "auid"
        case isResidential = "isResidential"
    }
}
