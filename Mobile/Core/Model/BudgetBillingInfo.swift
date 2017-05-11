//
//  BudgetBillingInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func extractAvMonthlyBill(object: Any?) throws -> String? {
    // We're checking for both a double or a string here, because they've changed their web services
    // here before and I want to protect against that possibility again
    if let doubleVal = object as? Double {
        return String(format: "$%.02f", locale: Locale.current, arguments: [doubleVal])
    } else if let stringVal = object as? String {
        if let doubleVal = NumberFormatter().number(from: stringVal)?.doubleValue {
            return String(format: "$%.02f", locale: Locale.current, arguments: [doubleVal])
        } else {
            throw MapperError.convertibleError(value: stringVal, type: Double.self)
        }
    } else {
        throw MapperError.convertibleError(value: object, type: Double.self)
    }
}

struct BudgetBillingInfo: Mappable {
    let enrolled: Bool
    let averageMonthlyBill: String?
    
    init(map: Mapper) throws {

        do {
            try enrolled = map.from("enrolled")
        } catch {
            enrolled = false
        }

        averageMonthlyBill = map.optionalFrom("averageMonthlyBill", transformation: extractAvMonthlyBill)
    }
}
