//
//  BillingHistoryItem.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func dollarAmount(fromValue value: Any?) throws -> Double {
    /* We're checking for both a double or a string here, because they've changed
       their web services here before and I want to protect against that possibility again */
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

enum BillingHistoryStatus {
    case scheduled
    case pending
    case success
    case failed
    case canceled
    case returned
    case refunded
    case unknown
    
    init(identifier: String?) {
        guard let id = identifier?.lowercased() else {
            self = .unknown
            return
        }
        
        switch id {
        case "scheduled":
            self = .scheduled
        case "pending":
            self = .pending
        case "posted", "accepted":
            self = .success
        case "failed", "declined":
            self = .failed
        case "cancelled", "void":
            self = .canceled
        case "returned":
            self = .returned
        case "refunded":
            self = .refunded
        default:
            self = .unknown
        }
    }
}

struct BillingHistoryItem: Mappable {
    let amountPaid: Double?
    let date: Date
    let description: String?
    let maskedWalletItemAccountNumber: String?
    let paymentId: String?
    let statusString: String?
    let status: BillingHistoryStatus
    let totalAmountDue: Double? // Only sent when isBillPDF = true
    let paymentMethodType: PaymentMethodType?
    let confirmationNumber: String?
    let convenienceFee: Double?
    let totalAmount: Double?
    let documentID: String?
    
    let isAutoPayPayment: Bool
    let isFuelFundDonation: Bool
    let isBillPDF: Bool
    
    var isFuture: Bool {
        if isBillPDF { // EM-2638: Bills should always be in the past
            return false
        }
        
        switch status {
        case .scheduled, .pending:
            return true
        case .success, .failed, .canceled, .returned, .refunded, .unknown:
            return false
        }
    }

    init(map: Mapper) throws {
        amountPaid = map.optionalFrom("amount_paid", transformation: dollarAmount)
        try date = map.from("date", transformation: DateParser().extractDate)
        description = map.optionalFrom("description")
        maskedWalletItemAccountNumber = map.optionalFrom("masked_wallet_item_account_number", transformation: extractLast4)
        paymentId = map.optionalFrom("payment_id")
        documentID = map.optionalFrom("documentID")
        // Historical payments send "confirmation_number". For Paymentus, the paymentId is the confirmation number
        if let confNum: String = map.optionalFrom("confirmation_number") {
            confirmationNumber = confNum
        } else if let pid: String = map.optionalFrom("payment_id"), !pid.isEmpty {
            confirmationNumber = pid
        } else {
            confirmationNumber = nil
        }

        totalAmountDue = map.optionalFrom("total_amount_due")
        convenienceFee = map.optionalFrom("convenience_fee")
        totalAmount = map.optionalFrom("total_amount")
        
        statusString = map.optionalFrom("status")
        status = BillingHistoryStatus(identifier: statusString)
        
        if let paymentusPaymentMethodType: String = map.optionalFrom("payment_type") {
            paymentMethodType = paymentMethodTypeForPaymentusString(paymentusPaymentMethodType)
        } else {
            paymentMethodType = nil
        }
        
        if let channel: String = map.optionalFrom("channel_code") {
            isAutoPayPayment = channel == "SCHEDULED_PAYMENT"
            isFuelFundDonation = channel == "FFD"
        } else {
            isAutoPayPayment = false
            isFuelFundDonation = false
        }
        
        if let type: String = map.optionalFrom("type") {
            isBillPDF = type == "billing"
        } else {
            isBillPDF = false
        }
    }
}
