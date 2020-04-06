//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewScheduledPayment: Encodable {
    public var paymentType: String
    public var walletId: String
    public var walletItemId: String
    public var billerId: String
    public var maskedAccountNumber: String
    public var isExistingAccount: Bool
    public var paymentAmount: String
    public var paymentDate: String
    
    enum CodingKeys: String, CodingKey {
        case paymentType = "payment_category_type"
        case walletId = "wallet_id"
        case walletItemId = "wallet_item_id"
        case billerId = "biller_id"
        case maskedAccountNumber = "masked_wallet_item_account_number"
        case isExistingAccount = "is_existing_account"
        case paymentAmount = "payment_amount"
        case paymentDate = "payment_date"
    }
}
