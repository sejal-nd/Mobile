//
//  Payments.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct Payments: Decodable {
    public var isEbillEligible: Bool?
    public var billingInfo: PaymentBillingInfo?
    
    enum CodingKeys: String, CodingKey {
        case isEbillEligible = "isEBillEligible"
        case billingInfo = "BillingInfo"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.isEbillEligible = try container.decodeIfPresent(Bool.self,
                                               forKey: .isEbillEligible)
        self.billingInfo = try container.decodeIfPresent(PaymentBillingInfo.self,
                                           forKey: .billingInfo)
    }
}

public struct PaymentBillingInfo: Decodable {
    public var payments: [PaymentItem]
}
