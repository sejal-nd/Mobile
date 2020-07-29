//
//  NewSchedulePaymentResult.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewBillingHistoryResult: Decodable {
    public var billingHistoryItems: [NewBillingHistoryItem]
    public let upcoming: [NewBillingHistoryItem]
    public let past: [NewBillingHistoryItem]
    public let mostRecentSixMonths: [NewBillingHistoryItem]
    
    enum CodingKeys: String, CodingKey {
        case billingHistoryItems = "billing_and_payment_history"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        billingHistoryItems = try container.decode([NewBillingHistoryItem].self,
                                                   forKey: .billingHistoryItems)
        
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
    
    init(upcoming: [NewBillingHistoryItem], past: [NewBillingHistoryItem]) {
        self.billingHistoryItems = upcoming + past
        self.upcoming = upcoming
        self.past = past
        self.mostRecentSixMonths = []
    }
}
