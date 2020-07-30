//
//  AutopayRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AutoPayEnrollBGERequest: Encodable {
    let amountType: String
    let paymentDateType: String
    let paymentDaysBeforeDue: String
    let requestType: String
    let walletItemId: String?
    let amountThreshold: String?
    
    enum CodingKeys: String, CodingKey {
        case amountType = "amount_type"
        case paymentDateType = "payment_date_type"
        case paymentDaysBeforeDue = "payment_days_before_due"
        case requestType = "auto_pay_request_type"
        case walletItemId = "wallet_item_id"
        case amountThreshold = "amount_threshold"
    }
}
