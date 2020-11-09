//
//  AccountLookupResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AccountLookupResult: Decodable {
    let accountNumber: String?
    let streetNumber: String?
    let unitNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case accountDetails = "AccountDetails"
        case accountNumber = "AccountNumber"
        case streetNumber = "StreetNumber"
        case unitNumber = "ApartmentUnitNumber"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let accountDetails = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .accountDetails)
        
        accountNumber = try accountDetails.decodeIfPresent(String.self, forKey: .accountNumber)
        streetNumber = try accountDetails.decodeIfPresent(String.self, forKey: .streetNumber)
        unitNumber = try accountDetails.decodeIfPresent(String.self, forKey: .unitNumber)
    }
}
