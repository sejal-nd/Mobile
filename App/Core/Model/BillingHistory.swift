//
//  BillingHistory.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct BillingHistory: Mappable {
    let billingHistoryItems: [BillingHistoryItem]
    let upcoming: [BillingHistoryItem]
    let past: [BillingHistoryItem]
    let mostRecentSixMonths: [BillingHistoryItem]
    
    init(map: Mapper) throws {
        billingHistoryItems = map.optionalFrom("billing_and_payment_history")?.sorted(by: { $0.date > $1.date }) ?? []
        upcoming = billingHistoryItems.filter{ $0.isFuture }.sorted(by: { $0.date < $1.date })
        past = billingHistoryItems.filter { !$0.isFuture }.sorted(by: { $0.date > $1.date })
        
        if !past.isEmpty {
            let firstPastDate = past.first!.date
            let sixMonthsFromFirstPastDate = Calendar.opCo.date(byAdding: .month, value: -6, to: firstPastDate)!
            mostRecentSixMonths = past.filter { $0.date > sixMonthsFromFirstPastDate }
        } else {
            mostRecentSixMonths = []
        }
    }
    
    init(upcoming: [BillingHistoryItem], past: [BillingHistoryItem]) {
        self.billingHistoryItems = upcoming + past
        self.upcoming = upcoming
        self.past = past
        self.mostRecentSixMonths = []
    }
}

