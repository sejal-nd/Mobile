//
//  Payment.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

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

struct PaymentDetail: Mappable {
    var walletItemId: String?
    var paymentAmount: Double
    var paymentDate: Date?
    var convenienceFee: Double?
    var paymentAccount: String?
    var accountNumber: String?
    
    init(map: Mapper) throws {
        walletItemId = map.optionalFrom("wallet_item_id")
        paymentAmount = map.optionalFrom("payment_amount") ?? 0
        paymentDate = map.optionalFrom("payment_date", transformation: DateParser().extractDate)
        convenienceFee = map.optionalFrom("convenience_fee")
        paymentAccount = map.optionalFrom("payment_account")
        accountNumber = map.optionalFrom("account_number")
    }
    
    init(walletItemId: String?, paymentAmount: Double, paymentDate: Date?) {
        self.walletItemId = walletItemId
        self.paymentAmount = paymentAmount
        self.paymentDate = paymentDate
    }
}
