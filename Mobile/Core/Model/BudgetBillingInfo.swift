//
//  BudgetBillingInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 4/28/17.
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

struct BudgetBillingInfo: Mappable {
    let averageMonthlyBill: String?
    let budgetBillDifference: String? // Only used for BGE Footer View
    let budgetBillDifferenceDecimal: Double
    let budgetBillBalance: String? // Only used for BGE Footer View
    let budgetBillPayoff: String? // Only used for BGE Footer View
    let isUSPPParticipant: Bool // BGE only
    let budgetBill: String?
    
    init(map: Mapper) throws {
        averageMonthlyBill = map.optionalFrom("averageMonthlyBill", transformation: extractDollarAmountString)
        budgetBillDifference = map.optionalFrom("budgetBillDifference", transformation: extractDollarAmountString)
        budgetBillBalance = map.optionalFrom("budgetBillBalance", transformation: extractDollarAmountString)
        budgetBillPayoff = map.optionalFrom("budgetBillPayoff", transformation: extractDollarAmountString)
        budgetBill = map.optionalFrom("budgetBill", transformation: extractDollarAmountString)
        
        if let programCode: String = map.optionalFrom("programCode"), programCode == "USPPBDPL" {
            isUSPPParticipant = true
        } else {
            isUSPPParticipant = false
        }
        
        do {
            try budgetBillDifferenceDecimal = map.from("budgetBillDifference")
        } catch {
            budgetBillDifferenceDecimal = 0
        }
    }
}
