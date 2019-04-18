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
    
    let isAutoPayPayment: Bool
    let isFuelFundDonation: Bool
    let isBillPDF: Bool
    
    var isFuture: Bool {
        switch status {
        case .pending:
            return true
        case .canceled: // EM-2638: Canceled payments should always be in the past
            return false
        default:
            if isBillPDF { // EM-2638: Bills should always be in the past
                return false
            }
            return date >= Calendar.opCo.startOfDay(for: .now)
        }
    }

    init(map: Mapper) throws {
        amountPaid = map.optionalFrom("amount_paid", transformation: dollarAmount)
        try date = map.from("date", transformation: DateParser().extractDate)
        description = map.optionalFrom("description")
        maskedWalletItemAccountNumber = map.optionalFrom("masked_wallet_item_account_number", transformation: extractLast4)
        paymentId = map.optionalFrom("payment_id")
        
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
        
        // FYI - this seems backwards but is actually correct. "payment_type" returns the type of
        // wallet item used (CHQ/SAV/VISA/MC). We use that to display the correct bank/card icon
        // under the "Payment Method" label on the detail screen
        if let paymentusPaymentMethodType: String = map.optionalFrom("payment_type") {
            paymentMethodType = paymentMethodTypeForPaymentusString(paymentusPaymentMethodType)
        } else {
            paymentMethodType = nil
        }
        
        // Meanwhile, "payment_method" gives us details on the type of payment (for our purposes,
        // detecting whether it's a scheduled AutoPay payment or a Fuel Fund donation).
        // We display that under the "Payment Type" label on the detail screen 😖
        if let method: String = map.optionalFrom("payment_method") {
            isAutoPayPayment = method.lowercased() == "autopay"
            isFuelFundDonation = method.lowercased() == "fuelfunddonation"
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
