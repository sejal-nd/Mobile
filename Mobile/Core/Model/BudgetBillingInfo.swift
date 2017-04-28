//
//  BudgetBillingInfo.swift
//  Mobile
//
//  Created by Marc Shilling on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct BudgetBillingInfo: Mappable {
    let enrolled: Bool
    let averageMonthlyBill: String?
    
    init(map: Mapper) throws {

        do {
            try enrolled = map.from("enrolled")
        } catch {
            enrolled = false
        }

        averageMonthlyBill = map.optionalFrom("averageMonthlyBill")
    }
}
