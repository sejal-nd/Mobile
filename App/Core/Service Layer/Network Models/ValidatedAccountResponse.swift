//
//  ValidatedAccount.swift
//  Mobile
//
//  Created by Cody Dillon on 5/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct ValidatedAccountResponse: Decodable {
    let type: [String]?
    var isEbill: Bool? = false
    var multipleCustomers: Bool? = false
    var accounts: [AccountResult]
    var accountNumbers: [String]
    var customerName: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case isEbill = "ebill"
        case multipleCustomers
        case accounts
        case customerName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decodeIfPresent([String].self, forKey: .type)
        isEbill = try container.decodeIfPresent(Bool.self, forKey: .isEbill)
        multipleCustomers = try container.decodeIfPresent(Bool.self, forKey: .multipleCustomers)
        accounts = (try? container.decodeIfPresent([AccountResult].self, forKey: .accounts)) ?? []
        accountNumbers = (try? container.decodeIfPresent([String].self, forKey: .accounts)) ?? []
        customerName = try container.decodeIfPresent(String.self, forKey: .customerName)
    }
}
