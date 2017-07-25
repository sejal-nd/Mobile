//
//  Payment.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct Payment {
    var accountNumber : String
    var existingAccount : Bool
    var saveAccount : Bool
    var maskedWalletAccountNumber : String
    var paymentAmount : Double
    var paymentType : PaymentType
    var paymentDate : Date
    var walletId : String
    var walletItemId : String
    var cvv : String?
    
    init(accountNumber: String,
         existingAccount: Bool,
         saveAccount: Bool,
         maskedWalletAccountNumber: String,
         paymentAmount: Double,
         paymentType: PaymentType,
         paymentDate: Date,
         walletId: String,
         walletItemId: String,
         cvv: String? = nil) {
        self.accountNumber = accountNumber
        self.existingAccount = existingAccount
        self.saveAccount = saveAccount
        self.maskedWalletAccountNumber = maskedWalletAccountNumber
        self.paymentAmount = paymentAmount
        self.paymentType = paymentType
        self.paymentDate = paymentDate
        self.walletId = walletId
        self.walletItemId = walletItemId
        self.cvv = cvv
    }
}

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    return dateString.apiFormatDate
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
        paymentDate = map.optionalFrom("payment_date", transformation: extractDate)
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
