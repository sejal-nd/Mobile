//
//  WalletItemRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 8/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct WalletItemRequest: Encodable {
    let accountNumber: String
    let maskedAccountNumber: String
    let paymentCategoryType: String
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case maskedAccountNumber = "masked_wallet_item_acc_num"
        case paymentCategoryType = "payment_category_type"
    }
}
