//
//  NewAccounts.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// we want this to return an array of objects as opposed to a single object.
public struct NewAccounts: Decodable {
    public var accounts: [NewAccount]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.accounts = try container.decode([NewAccount].self)
    }
    
    // we want this to return an array of objects as opposed to a single object.
    public struct NewAccount: Decodable {
        public var accountNumber: String
        
        enum CodingKeys: String, CodingKey {
            case accountNumber
        }
    }
    
}

