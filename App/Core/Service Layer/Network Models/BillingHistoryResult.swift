//
//  NewSchedulePaymentResult.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct BillingHistoryResult: Decodable {
    public var billingHistoryItems: [BillingHistoryItem]
    public let upcoming: [BillingHistoryItem]
    public let past: [BillingHistoryItem]
    public let mostRecentSixMonths: [BillingHistoryItem]
    
    enum CodingKeys: String, CodingKey {
        case billingHistoryItems = "billing_and_payment_history"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let optionalDateItems = try container.decode([BillingHistoryItem].self, forKey: .billingHistoryItems)
        billingHistoryItems = optionalDateItems.filter({ $0._date != nil && $0.kwhElec != nil })
                
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
