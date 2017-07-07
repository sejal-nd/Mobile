//
//  Payment.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

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
