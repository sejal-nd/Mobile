//
//  UpdateScheduledPaymentRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ScheduledPaymentUpdateRequest: Encodable {
    let paymentAmount: String
    let paymentDate: String
    let paymentId: String
    let paymentCategoryType: String
    let walletId: String
    let billerId: String
    let walletItemId: String?
    let isExistingAccount: Bool?
    let maskedWalletItemAccountNumber: String?
    let alternateEmail: String?
    let alternatePhoneNumber: String?
    
    init(paymentAmount: Double,
             paymentDate: Date,
             paymentId: String,
             walletId: String = AccountsStore.shared.customerIdentifier,
             walletItem: WalletItem,
             alternateEmail: String? = nil,
             alternatePhoneNumber: String? = nil) {
        self.paymentAmount = String.init(format: "%.02f", paymentAmount)
        self.paymentDate = paymentDate.paymentFormatString
        self.paymentCategoryType = walletItem.bankOrCard == .bank ? "Check" : "Credit"
        self.walletId = walletId
        self.paymentId = paymentId
        self.billerId = "\(Environment.shared.opco.rawValue)Registered"
        self.walletItemId = walletItem.walletItemId
        self.isExistingAccount = !walletItem.isTemporary
        self.maskedWalletItemAccountNumber = walletItem.maskedWalletItemAccountNumber
        
        self.alternateEmail = alternateEmail
        self.alternatePhoneNumber = alternatePhoneNumber
    }
    
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
        
        case alternateEmail = "email_id"
        case alternatePhoneNumber = "mobile_phone_number"
    }
}
