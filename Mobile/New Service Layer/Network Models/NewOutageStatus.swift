//
//  NewOutageStatus.swift
//  Mobile
//
//  Created by Cody Dillon on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewOutageStatus: Decodable {
    let flagGasOnly: Bool
    let contactHomeNumber: String?
    let outageDescription: String?
    let activeOutage: Bool // "ACTIVE", "NOT ACTIVE"
    let smartMeterStatus: Bool
    var flagFinaled: Bool
    var flagNoPay: Bool
    var flagNonService: Bool
    var etr: Date?
    let locationId: String?
    
    // Unauthenticated fields
    let accountNumber: String?
    let maskedAccountNumber: String?
    let maskedAddress: String?
    let addressNumber: String?
    let unitNumber: String?
    var multipremiseAccount: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case flagGasOnly = "flagGasOnly"
        case contactHomeNumber = "contactHomeNumber"
        case outageDescription = "outageDescription"
        case activeOutage = "activeOutage"
        case smartMeterStatus = "smartMeterStatus"
        case flagFinaled = "flagFinaled"
        case flagNoPay = "flagNoPay"
        case flagNonService = "flagNonService"
        case etr = "ETR"
        case locationId = "locationId"
        case accountNumber = "accountNumber"
        case maskedAccountNumber = "maskedAccountNumber"
        case maskedAddress = "maskedAddress"
        case addressNumber = "addressNumber"
        case unitNumber = "unitNumber"
        case multipremiseAccount = "multipremiseAccount"
    }
}
