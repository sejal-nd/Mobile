//
//  BudgetBillingInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func extractAvMonthlyBill(object: Any?) throws -> String? {
    guard let string = object as? String else {
        throw MapperError.convertibleError(value: object, type: String.self)
    }
    
    if let doubleVal = NumberFormatter().number(from: string)?.doubleValue {
        return String(format: "$%.02f", locale: Locale.current, arguments: [doubleVal])
    } else {
        throw MapperError.convertibleError(value: string, type: Double.self)
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
