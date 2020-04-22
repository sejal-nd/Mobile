//
//  UpdateScheduledPaymentRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct ScheduledPaymentUpdateRequest: Encodable {
    let paymentAmount: String
    let paymentDate: String
    let paymentCategoryType: String
    var paymentId: String?
    let walletId: String
    let billerId: String
    let walletItemId: String?
    let isExistingAccount: Bool?
    let maskedWalletItemAccountNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentAmount = "payment_amount"
        case paymentDate = "payment_date"
        case paymentCategoryType = "payment_category_type"
        case paymentId = "payment_id"
        case walletId = "wallet_id"
        case billerId = "biller_id"
        case walletItemId = "wallet_item_id"
        case isExistingAccount = "is_existing_account"
        case maskedWalletItemAccountNumber = "masked_wallet_item_account_number"
    }
}
