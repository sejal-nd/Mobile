//
//  OutageStatus.swift
//  Mobile
//
//  Created by Cody Dillon on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageStatus: Decodable {
    var isGasOnly = false
    let contactHomeNumber: String?
    let outageDescription: String?
    var isActiveOutage = false // "ACTIVE", "NOT ACTIVE"
    var isSmartMeter = false
    var isFinaled = false
    var isNoPay = false
    var isNonService = false
    var estimatedRestorationDate: Date?
    let locationId: String?
    
    // Unauthenticated fields
    let accountNumber: String?
    let premiseNumber: String?
    let maskedAccountNumber: String?
    let maskedAddress: String?
    let addressNumber: String?
    let unitNumber: String?
    var multipremiseAccount = false
    var isInactive = false // what is this?
    
    enum CodingKeys: String, CodingKey {
        case isGasOnly = "flagGasOnly"
        case contactHomeNumber = "contactHomeNumber"
        case outageDescription = "outageReported"
        case isActiveOutage = "activeOutage"
        case isSmartMeter = "smartMeterStatus"
        case isFinaled = "flagFinaled"
        case isNoPay = "flagNoPay"
        case isNonService = "flagNonService"
        case estimatedRestorationDate = "ETR"
        case locationId = "locationId"
        case accountNumber = "accountNumber"
        case premiseNumber = "premiseNumber"
        case maskedAccountNumber = "maskedAccountNumber"
        case maskedAddress = "maskedAddress"
        case addressNumber = "addressNumber"
        case unitNumber = "unitNumber"
        case multipremiseAccount = "multipremiseAccount"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.contactHomeNumber = try container.decodeIfPresent(String.self,
                                                               forKey: .contactHomeNumber)
        self.outageDescription = try container.decodeIfPresent(String.self,
                                                               forKey: .outageDescription)
        self.isActiveOutage = (try container.decodeIfPresent(String.self,
                                                             forKey: .isActiveOutage) ?? "NOT ACTIVE") == "ACTIVE"
        self.isGasOnly = try container.decodeIfPresent(Bool.self,
                                                       forKey: .isGasOnly) ?? false
        self.isSmartMeter = try container.decodeIfPresent(Bool.self,
                                                          forKey: .isSmartMeter) ?? false
        self.isFinaled = try container.decodeIfPresent(Bool.self,
                                                       forKey: .isFinaled) ?? false
        self.isNoPay = try container.decodeIfPresent(Bool.self,
                                                     forKey: .isNoPay) ?? false
        self.isNonService = try container.decodeIfPresent(Bool.self,
                                                          forKey: .isNonService) ?? false
        self.estimatedRestorationDate = try container.decodeIfPresent(Date.self,
                                                                      forKey: .estimatedRestorationDate)
        self.locationId = try container.decodeIfPresent(String.self,
                                                        forKey: .locationId)
        self.accountNumber = try container.decodeIfPresent(String.self,
                                                           forKey: .accountNumber)
        self.premiseNumber = try container.decodeIfPresent(String.self,
                                                           forKey: .premiseNumber)
        self.maskedAccountNumber = try container.decodeIfPresent(String.self,
                                                                 forKey: .maskedAccountNumber)
        self.maskedAddress = try container.decodeIfPresent(String.self,
                                                           forKey: .maskedAddress)
        self.addressNumber = try container.decodeIfPresent(String.self,
                                                           forKey: .addressNumber)
        self.unitNumber = try container.decodeIfPresent(String.self,
                                                        forKey: .unitNumber)
        self.multipremiseAccount = try container.decodeIfPresent(Bool.self,
                                                                 forKey: .multipremiseAccount) ?? false
    }
}
