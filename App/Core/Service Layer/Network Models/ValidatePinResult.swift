//
//  ValidatePinResult.swift
//  Mobile
//
//  Created by Tiwari, Anurag on 01/06/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ValidatePinResult : Decodable {
    var accounts: [AccountDetails]?
    var isMultiple: Bool?
    var usernames: [Username]?
    
    enum CodingKeys: String, CodingKey {
        case accounts = "accounts"
        case isMultiple = "isMultiple"
        case usernames = "usernames"
    }
}
    
// MARK: - Account
struct AccountDetails: Decodable {
    public  var accountNumber: String?
    public  var streetNumber: String?
    public  var unitNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case streetNumber = "street"
        case unitNumber = "unit"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.accountNumber = try container.decodeIfPresent(String.self,forKey: .accountNumber)
        self.streetNumber = try container.decodeIfPresent(String.self,forKey: .streetNumber)
        self.unitNumber = try container.decodeIfPresent(String.self,forKey: .unitNumber)
    }
}

// MARK: - Username
struct Username: Decodable {
    var email: String?
}

