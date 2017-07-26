//
//  BillingHistory.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct BillingHistory: Mappable {
    let billingHistoryItems: Array<BillingHistoryItem>
    let upcoming: Array<BillingHistoryItem>
    let past: Array<BillingHistoryItem>
    let pastSixMonths: Array<BillingHistoryItem>
    
    init(map: Mapper) throws {
        billingHistoryItems = map.optionalFrom("billing_and_payment_history")?.sorted(by: { $0.date > $1.date }) ?? []
        upcoming = billingHistoryItems.filter{ $0.isFuture }.sorted(by: { $0.date < $1.date })
        past = billingHistoryItems.filter { !$0.isFuture }.sorted(by: { $0.date > $1.date })
        
        let calendar = Calendar.current
        let sixMonths = calendar.date(byAdding: .month, value: -6, to: Date())
        
        pastSixMonths = billingHistoryItems.filter { !$0.isFuture }.filter { $0.date > sixMonths! }
    }
}

