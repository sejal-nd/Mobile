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
    case processing
    case processed
    case canceled
    case failed
    case unknown
    case accepted
    
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
        case "processing":
            self = .processing
        case "processed":
            self = .processed
        case "canceled", "cancelled", "void":
            self = .canceled
        case "failed", "declined", "returned":
            self = .failed
        case "accepted", "posted", "complete":
            self = .accepted
        default:
            self = .unknown
        }
    }
}

struct BillingHistoryItem: Mappable {
    let amountPaid: Double?
    let chargeAmount: Double?
    let totalAmountDue: Double?
    let date: Date
    let description: String?
    let statusString: String?
    let status: BillingHistoryStatus
    let confirmationNumber: String?
    let paymentType: String?
    let isBillPDF: Bool
    let paymentMethod: String?
    let paymentId: String?
    let walletItemId: String?
    let flagAllowDeletes: Bool // BGE only - ComEd/PECO default to true
    let flagAllowEdits: Bool // BGE only - ComEd/PECO default to true
    
    var isFuture: Bool {
        switch status {
        case .pending, .processing, .processed:
            return true
        case .canceled, .accepted: // EM-2638: Canceled payments should always be in the past
            return false
        case .scheduled, .failed, .unknown:
            if isBillPDF { // EM-2638: Bills should always be in the past
                return false
            }
            
            return date >= Calendar.opCo.startOfDay(for: .now)
        }
    }

    init(map: Mapper) throws {
        amountPaid = map.optionalFrom("amount_paid", transformation: dollarAmount)
        chargeAmount = map.optionalFrom("charge_amount", transformation: dollarAmount)
        totalAmountDue = map.optionalFrom("total_amount_due", transformation: dollarAmount)
        try date = map.from("date", transformation: DateParser().extractDate)
        description = map.optionalFrom("description")

        statusString = map.optionalFrom("status")
        status = BillingHistoryStatus(identifier: statusString)
        
        confirmationNumber = map.optionalFrom("confirmation_number")
        paymentType = map.optionalFrom("payment_type")
        paymentMethod = map.optionalFrom("payment_method")
        if let type: String = map.optionalFrom("type") {
            isBillPDF = type == "billing"
        } else {
            isBillPDF = false
        }
        paymentId = map.optionalFrom("payment_id")
        walletItemId = map.optionalFrom("wallet_item_id")
        if Environment.shared.opco == .bge {
            flagAllowDeletes = map.optionalFrom("flag_allow_deletes") ?? true
            flagAllowEdits = map.optionalFrom("flag_allow_edits") ?? true
        } else {
            flagAllowDeletes = true
            flagAllowEdits = false
        }
    }
}
