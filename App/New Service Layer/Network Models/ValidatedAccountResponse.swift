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
    var isEbill: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case type
        case isEbill = "ebill"
    }
}
