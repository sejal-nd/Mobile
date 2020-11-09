//
//  WalletItemDeleteRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct WalletItemDeleteRequest: Encodable {
    let accountNumber: String
    let walletItemId: String
    let maskedAccountNumber: String
    let billerId: String
    let paymentCategoryType: String
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case walletItemId = "wallet_item_id"
        case maskedAccountNumber = "masked_wallet_item_acc_num"
        case billerId = "biller_id"
        case paymentCategoryType = "payment_category_type"
    }
}
