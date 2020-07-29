//
//  NewBudgetBilling.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewBudgetBilling: Decodable {
    public var isBudgetBillingAvailable: Bool
    public var isEnrolled: Bool
    public var averageMonthlyBill: Double
    public var budgetBill: Double?
    public var budgetBillDifference: Double?
    public var budgetBillBalance: Double?
    public var budgetBillPayoff: Double?
    public var programStatusCode: String
    public var programCode: String
    public var programStartDate: Date
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case isBudgetBillingAvailable = "isBudgetBillingAvailable"
        case isEnrolled = "enrolled"
        case averageMonthlyBill = "averageMonthlyBill"
        case budgetBill = "budgetBill"
        case budgetBillDifference = "budgetBillDifference"
        case budgetBillBalance = "budgetBillBalance"
        case budgetBillPayoff = "budgetBillPayoff"
        case programStatusCode = "programStatusCode"
        case programCode = "programCode"
        case programStartDate = "programStartDate"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        
        self.isBudgetBillingAvailable = try data.decode(Bool.self,
                                                        forKey: .isBudgetBillingAvailable)
        self.isEnrolled = try data.decode(Bool.self,
                                          forKey: .isEnrolled)
        
        self.averageMonthlyBill = try data.decode(Double.self,
                                                  forKey: .averageMonthlyBill)
        self.budgetBill = try data.decodeIfPresent(Double.self,
                                          forKey: .budgetBill)
        self.budgetBillDifference = try data.decodeIfPresent(Double.self,
                                                    forKey: .budgetBillDifference)
        self.budgetBillBalance = try data.decodeIfPresent(Double.self,
                                                 forKey: .budgetBillBalance)
        self.budgetBillPayoff = try data.decodeIfPresent(Double.self,
                                                forKey: .budgetBillPayoff)
        
        self.programStatusCode = try data.decode(String.self,
                                                 forKey: .programStatusCode)
        self.programCode = try data.decode(String.self,
                                           forKey: .programCode)
        
        self.programStartDate = try data.decode(Date.self,
                                                forKey: .programStartDate)
    }
}
