//
//  NewWallet.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewPayments: Decodable {
    public var isEbillEligible: Bool
    public var billingInfo: NewBillingInfo
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case isEbillEligible = "isEBillEligible"
        case billingInfo = "BillingInfo"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.isEbillEligible = try data.decode(Bool.self,
                                               forKey: .isEbillEligible)
        self.billingInfo = try data.decode(NewBillingInfo.self,
                                           forKey: .billingInfo)
    }
}

public struct NewBillingInfo: Decodable {
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
