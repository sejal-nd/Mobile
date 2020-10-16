//
//  BillingHistoryRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct PaymentRequest: Encodable {
    let category: String
    let postbackURL: String
    var ownerId: String? = nil
    let stringParameter: String
    var walletItemId: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case category = "pmCategory"
        case postbackURL = "postbackUrl"
        case ownerId = "ownerId"
        case stringParameter = "strParam"
        case walletItemId = "wallet_item_id"
    }
}
