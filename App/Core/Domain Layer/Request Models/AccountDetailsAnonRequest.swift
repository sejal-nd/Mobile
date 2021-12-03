//
//  AccountDetailsAnonRequest.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountDetailsAnonRequest: Encodable {

    let phoneNumber: String?
    let accountNumber: String
    let identifier: String
    
    init(phoneNumber: String, accountNumber: String, identifier: String) {

        self.phoneNumber = phoneNumber
        self.accountNumber = accountNumber
        self.identifier = identifier
    }
    
    enum CodingKeys: String, CodingKey {
        
        case phoneNumber = "phone"
        case accountNumber = "AccountNumber"
        case identifier = "identifier"
    }
}
