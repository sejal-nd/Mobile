//
//  BGEAutoPayInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

enum AmountType: String {
    case UpToAmount = "upto amount"
    case AmountDue = "amount due"
}

enum PaymentDateType: String {
    case OnDueDate = "on due"
    case BeforeDueDate = "before due"
}

enum EffectivePeriod: String {
    case UntilCancelled = "untilCanceled"
    case EndDate = "endDate"
    case MaxPayments = "maxPayments"
}

struct BGEAutoPayInfo: Mappable {
    
//    let paymentAccount: String?
//    let amountType: AmountType?
//    let amountThreshold: String?
//    let paymentDateType: PaymentDateType?
//    let paymentDaysBeforeDue: String?
//    let effectivePeriod: EffectivePeriod?
//    let effectiveEndDate: Date? // Only required if effectivePeriod is endDate
//    let effectiveNumPayments: String? // Only required if effectivePeriod is maxPayments
    
    init(map: Mapper) throws {
        
    }
}
