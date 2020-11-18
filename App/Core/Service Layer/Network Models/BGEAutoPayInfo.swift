//
//  NewBGEAutoPayInfo.swift
//  Mobile
//
//  Created by Cody Dillon on 7/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum AmountType: String, Decodable {
    case upToAmount = "upto amount"
    case amountDue = "amount due"
}

public struct BGEAutoPayInfo: Decodable {
    let walletItemId: String?
    let dateSetup: String?
    let numberOfPaymentsScheduled: String?
    let maskedAccountNumber: String?
    let amountType: AmountType?
    let paymentDateType: String?
    let confirmationNumber: String
    let amountThreshold: Double?
    let paymentDaysBeforeDue: String?
    
    enum CodingKeys: String, CodingKey {
        case dateSetup = "date_setup"
        case numberOfPaymentsScheduled = "no_of_payments_scheduled"
        case amountType = "amount_type"
        case paymentDateType = "payment_date_type"
        case maskedAccountNumber = "masked_account_number"
        case walletItemId = "wallet_item_id"
        case confirmationNumber = "confirmation_number"
        case amountThreshold = "amount_threshold"
        case paymentDaysBeforeDue = "payment_days_before_due"
    }
}
