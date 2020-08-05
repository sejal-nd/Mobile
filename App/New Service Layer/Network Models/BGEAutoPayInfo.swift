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
    let paymentAccountNickname: String?
    let paymentAccountLast4: String?
    let amountType: AmountType?
    let amountThreshold: Double?
    let paymentDaysBeforeDue: Int?
    let confirmationNumber: String
}
