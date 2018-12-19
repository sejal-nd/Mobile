//
//  BillingHistoryItem.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func dollarAmount(fromValue value: Any?) throws -> Double {
    // We're checking for both a double or a string here, because they've changed their web services
    // here before and I want to protect against that possibility again
    if let doubleVal = value as? Double {
        return doubleVal
    } else if let stringVal = value as? String {
        if let doubleVal = NumberFormatter().number(from: stringVal)?.doubleValue {
            return doubleVal
        } else {
            throw MapperError.convertibleError(value: stringVal, type: Double.self)
        }
    } else {
        throw MapperError.convertibleError(value: value, type: Double.self)
    }
}

private func calculateIsFuture(dateToCompare: Date) -> Bool {
    let calendar = Calendar.current
    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
    return dateToCompare > yesterday!
}

struct BillingHistoryItem: Mappable {
    let amountPaid: Double?
    let chargeAmount: Double?
    let totalAmountDue: Double?
    let date: Date
    let description: String?
    let status: String?
    var isFuture: Bool
    let confirmationNumber: String?
    let paymentType: String?
    let type: String?
    let paymentMethod: String?
    let paymentId: String?
    let walletItemId: String?
    let flagAllowDeletes: Bool // BGE only - ComEd/PECO default to true
    let flagAllowEdits: Bool // BGE only - ComEd/PECO default to true
    let encryptedPaymentId: String?
    
    init(map: Mapper) throws {
        amountPaid = map.optionalFrom("amount_paid", transformation: dollarAmount)
        chargeAmount = map.optionalFrom("charge_amount", transformation: dollarAmount)
        totalAmountDue = map.optionalFrom("total_amount_due", transformation: dollarAmount)
        try date = map.from("date", transformation: DateParser().extractDate)
        description = map.optionalFrom("description")
        status = map.optionalFrom("status")
        confirmationNumber = map.optionalFrom("confirmation_number")
        paymentType = map.optionalFrom("payment_type")
        paymentMethod = map.optionalFrom("payment_method")
        type = map.optionalFrom("type")
        paymentId = map.optionalFrom("payment_id")
        walletItemId = map.optionalFrom("wallet_item_id")
        flagAllowDeletes = map.optionalFrom("flag_allow_deletes") ?? true
        flagAllowEdits = map.optionalFrom("flag_allow_edits") ?? false
        encryptedPaymentId = map.optionalFrom("encrypted_payment_id")
        isFuture = calculateIsFuture(dateToCompare: date)
        if status == BillingHistoryProperties.statusPending.rawValue ||
            status == BillingHistoryProperties.statusProcessing.rawValue ||
            status == BillingHistoryProperties.statusProcessed.rawValue {
            isFuture = true
        } else if status == BillingHistoryProperties.statusCanceled.rawValue || status == BillingHistoryProperties.statusCANCELLED.rawValue {
            // EM-2638: Cancelled payments should always be in the past
            isFuture = false
        } else if type == BillingHistoryProperties.typeBilling.rawValue {
            // EM-2638: Bills should always be in the past
            isFuture = false
        }
    }
}

enum BillingHistoryProperties: String {
    case typeBilling = "billing"
    case typePayment = "payment"
    case statusCanceled = "canceled"
    case statusCANCELLED = "CANCELLED" //PECO
    case statusPosted = "Posted"
    case statusFailed = "failed"
    case statusPending = "Pending" //TODO: need to confirm case
    case statusProcessing = "processing"
    case statusProcessed = "processed"
    case statusScheduled = "scheduled"
    case statusSCHEDULED = "SCHEDULED" //PECO
    case paymentMethod_S = "S"
    case paymentMethod_R = "R"
    case paymentTypeSpeedpay = "SPEEDPAY"
    case paymentTypeCSS = "CSS"
}
