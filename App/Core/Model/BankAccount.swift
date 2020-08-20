//
//  BankAccount.swift
//  Mobile
//
//  Created by Kenny Roethel on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct BankAccount {
    var bankAccountNumber: String
    var routingNumber: String
    var accountNickname: String?
    var accountType: String?
    var accountName: String?
    var oneTimeUse: Bool
    
    init(bankAccountNumber: String,
         routingNumber: String,
         accountNickname: String?,
         accountType: String? = nil,
         accountName: String? = nil,
         oneTimeUse: Bool = false) {
        self.bankAccountNumber = bankAccountNumber
        self.routingNumber = routingNumber
        self.accountNickname = accountNickname
        self.accountType = accountType
        self.accountName = accountName
        self.oneTimeUse = oneTimeUse
    }

}
