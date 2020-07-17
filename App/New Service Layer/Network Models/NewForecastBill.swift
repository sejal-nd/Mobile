//
//  NewBudgetBilling.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewForecastBillContainer: Decodable {
    public var forecastMonthlyBills: [NewForecastBill]
}

public struct NewForecastBill: Decodable {
    public var billingStartDate: Date?
    public var billingEndDate: Date?
    public var calculationDate: Date?
    public var toDateUsage: Double?
    public var projectedUsage: Double?
    public var baselineUsage: Double?
    public var baselineCost: Double?
    public var currencySymbol: String?
    public var utilityAccountId: String?
    public var utilityAccountId2: String?
    public var meterType: String?
    public var meterUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case billingStartDate = "billingStartDate"
        case billingEndDate = "billingEndDate"
        case calculationDate = "calculationDate"
        case toDateUsage = "toDateUsage"
        case projectedUsage = "projectedUsage"
        case baselineUsage = "baselineUsage"
        case baselineCost = "baselineCost"
        case currencySymbol = "currencySymbol"
        case utilityAccountId = "utilityAccountId"
        case utilityAccountId2 = "utilityAccountId2"
        case meterType = "meterType"
        case meterUnit = "meterUnit"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.billingStartDate = try container.decodeIfPresent(Date.self,
                                                              forKey: .billingStartDate)
        self.billingEndDate = try container.decodeIfPresent(Date.self,
                                                            forKey: .billingEndDate)
        self.calculationDate = try container.decodeIfPresent(Date.self,
                                                             forKey: .calculationDate)
        self.toDateUsage = try container.decodeIfPresent(Double.self,
                                                         forKey: .toDateUsage)
        self.projectedUsage = try container.decodeIfPresent(Double.self,
                                                            forKey: .projectedUsage)
        self.baselineUsage = try container.decodeIfPresent(Double.self,
                                                           forKey: .baselineUsage)
        self.baselineCost = try container.decodeIfPresent(Double.self,
                                                          forKey: .baselineCost)
        self.currencySymbol = try container.decodeIfPresent(String.self,
                                                            forKey: .currencySymbol)
        self.utilityAccountId = try container.decodeIfPresent(String.self,
                                                              forKey: .utilityAccountId)
        self.utilityAccountId2 = try container.decodeIfPresent(String.self,
                                                               forKey: .utilityAccountId2)
        self.meterType = try container.decodeIfPresent(String.self,
                                                       forKey: .meterType)
        self.meterUnit = try container.decodeIfPresent(String.self,
                                                       forKey: .meterUnit)
    }
}
