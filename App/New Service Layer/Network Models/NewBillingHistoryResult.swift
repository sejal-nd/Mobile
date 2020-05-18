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
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case billingHistoryItems = "billing_and_payment_history"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.billingHistoryItems = try data.decode([NewBillingHistoryItem].self,
                                                   forKey: .billingHistoryItems)
    }
}
