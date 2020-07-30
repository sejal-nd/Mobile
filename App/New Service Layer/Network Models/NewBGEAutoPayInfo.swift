//
//  NewBGEAutoPayInfo.swift
//  Mobile
//
//  Created by Cody Dillon on 7/30/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum NewAmountType: String, Decodable {
    case upToAmount = "upto amount"
    case amountDue = "amount due"
}

public struct NewBGEAutoPayInfo: Decodable {
    let walletItemId: String?
    let paymentAccountNickname: String?
    let paymentAccountLast4: String?
    let amountType: NewAmountType?
    let amountThreshold: Double?
    let paymentDaysBeforeDue: Int?
    let confirmationNumber: String
}
