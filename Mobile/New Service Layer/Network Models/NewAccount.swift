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
    
    enum CodingKeys: String, CodingKey {
        case accounts = "data"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accounts = try container.decode([NewAccount].self,
                                             forKey: .accounts)
    }
}

// we want this to return an array of objects as opposed to a single object.
public struct NewAccount: Decodable {
    public var accountNumber: String
    
    enum CodingKeys: String, CodingKey {
        case accountNumber
    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
//                                                 forKey: .data)
//        let account = data.nestedUnkeyedContainer(forKey: <#T##NewAccount.CodingKeys#>)
////        self.accountNumber = try data.decode(String.self,
////                                       forKey: .accountNumber)
//    }
}
