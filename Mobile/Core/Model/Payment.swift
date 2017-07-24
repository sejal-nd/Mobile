//
//  Payment.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct Payment {
    let accountNumber: String
    let existingAccount: Bool
    let saveAccount: Bool
    let maskedWalletAccountNumber: String
    let paymentAmount: Double
    let paymentType: PaymentType
    let paymentDate: Date
    let walletId: String
    let walletItemId: String
    let cvv: String?
}
