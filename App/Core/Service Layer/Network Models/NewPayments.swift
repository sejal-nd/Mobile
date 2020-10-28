//
//  Payments.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct Payments: Decodable {
    public var isEbillEligible: Bool
    public var billingInfo: PaymentBillingInfo
    
    enum CodingKeys: String, CodingKey {
        case isEbillEligible = "isEBillEligible"
        case billingInfo = "BillingInfo"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.isEbillEligible = try container.decode(Bool.self,
                                               forKey: .isEbillEligible)
        self.billingInfo = try container.decode(PaymentBillingInfo.self,
                                           forKey: .billingInfo)
    }
}

public struct PaymentBillingInfo: Decodable {
    public var payments: [NewPayment]
}

public struct NewPayment: Decodable {
    public var amount: Double
    public var date: Date
    public var method: String
    public var status: String
    public var channelCode: String
    
    enum CodingKeys: String, CodingKey {
        case amount = "paymentAmount"
        case date = "paymentDate"
        case method = "paymentMethod"
        case status = "status"
        case channelCode = "paymentChannelCode"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.amount = try container.decode(Double.self,
                                           forKey: .amount)
        self.date = try container.decode(Date.self,
                                         forKey: .date)
        self.method = try container.decode(String.self,
                                           forKey: .method)
        self.status = try container.decode(String.self,
                                           forKey: .status)
        self.channelCode = try container.decode(String.self,
                                                forKey: .channelCode)
    }
}