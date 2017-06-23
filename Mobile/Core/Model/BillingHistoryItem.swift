//
//  BillingHistoryItem.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func extractDollarAmountString(object: Any?) throws -> String? {
    // We're checking for both a double or a string here, because they've changed their web services
    // here before and I want to protect against that possibility again
    if let doubleVal = object as? Double {
        return doubleVal.currencyString
    } else if let stringVal = object as? String {
        if let doubleVal = NumberFormatter().number(from: stringVal)?.doubleValue {
            return doubleVal.currencyString
        } else {
            throw MapperError.convertibleError(value: stringVal, type: Double.self)
        }
    } else {
        throw MapperError.convertibleError(value: object, type: Double.self)
    }
}

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return dateFormatter.date(from: dateString)
}

private func calculateIsFuture(dateToCompare: Date?) -> Bool {
    let today = Date()
    guard let dateToCompare = dateToCompare else {
        return false //what do I return here if date is nil?  Should this error
    }
    
    return dateToCompare > today
}

struct BillingHistoryItem: Mappable {
    let amountPaid: String?
    let chargeAmount: String?
    let totalAmountDue: String?
    let date: Date?
    let description: String?
    let status: String?
    let isFuture: Bool
    
    init(map: Mapper) throws {
        amountPaid = map.optionalFrom("amount_paid", transformation: extractDollarAmountString)
        chargeAmount = map.optionalFrom("charge_amount", transformation: extractDollarAmountString)
        totalAmountDue = map.optionalFrom("total_amount_due", transformation: extractDollarAmountString)
        date = map.optionalFrom("date", transformation: extractDate)
        description = map.optionalFrom("description")
        status = map.optionalFrom("description");
        isFuture = calculateIsFuture(dateToCompare: date)
    }
}
