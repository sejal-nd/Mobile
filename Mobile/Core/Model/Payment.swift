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
    
    init(map: Mapper) throws {
        walletItemId = map.optionalFrom("wallet_item_id")
        paymentAmount = map.optionalFrom("payment_amount") ?? 0
        paymentDate = map.optionalFrom("payment_date", transformation: extractDate)
    }
    
    init(walletItemId: String?, paymentAmount: Double, paymentDate: Date?) {
        self.walletItemId = walletItemId
        self.paymentAmount = paymentAmount
        self.paymentDate = paymentDate
    }
}
