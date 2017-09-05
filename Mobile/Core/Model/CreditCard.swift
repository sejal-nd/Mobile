//
//  CreditCard.swift
//  Mobile
//
//  Created by Kenny Roethel on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct CreditCard {
    var cardNumber: String
    var securityCode: String
    var cardHolderName: String?
    var expirationMonth: String
    var expirationYear: String
    var postalCode: String
    var nickname: String?
    var oneTimeUse: Bool
    
    init(cardNumber: String,
         securityCode: String,
         cardHolderName: String? = nil,
         expirationMonth: String,
         expirationYear: String,
         postalCode: String,
         nickname: String? = nil,
         oneTimeUse: Bool = false) {
        self.cardNumber = cardNumber
        self.securityCode = securityCode
        self.cardHolderName = cardHolderName
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.postalCode = postalCode
        self.nickname = nickname
        self.oneTimeUse = oneTimeUse
    }
}
