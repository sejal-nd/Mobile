//
//  BGEAutoPayInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

enum AmountType: String {
    case upToAmount = "upto amount"
    case amountDue = "amount due"
}

enum PaymentDateType: String {
    case onDueDate = "on due"
    case beforeDueDate = "before due"
}

enum EffectivePeriod: String {
    case untilCanceled = "untilCanceled"
    case endDate = "endDate"
    case maxPayments = "maxPayments"
}

private func extractLast4(object: Any?) throws -> String? {
    guard let string = object as? String else {
        throw MapperError.convertibleError(value: object, type: String.self)
    }
    return string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
}

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    return dateString.apiFormatDate
}

struct BGEAutoPayInfo: Mappable {
    
    let paymentAccountNickname: String?
    let paymentAccountLast4: String?
    let amountType: AmountType?
    let amountThreshold: String?
    let paymentDateType: PaymentDateType?
    let paymentDaysBeforeDue: String?
    let effectivePeriod: EffectivePeriod?
    let effectiveEndDate: Date?
    let effectiveNumPayments: String?
    
    init(map: Mapper) throws {
        paymentAccountNickname = map.optionalFrom("payment_acount") // Yes, this is mispelled
        paymentAccountLast4 = map.optionalFrom("masked_account_number", transformation: extractLast4)
        amountType = map.optionalFrom("amount_type")
        amountThreshold = map.optionalFrom("amount_threshold")
        paymentDateType = map.optionalFrom("payment_date_type")
        paymentDaysBeforeDue = map.optionalFrom("payment_days_before_due")
        effectivePeriod = map.optionalFrom("effective_period")
        effectiveEndDate = map.optionalFrom("effective_end_date", transformation: extractDate)
        effectiveNumPayments = map.optionalFrom("effective_number_of_payments")
    }
}
