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
        
        self.isBudgetBillingAvailable = try container.decode(Bool.self,
                                                        forKey: .isBudgetBillingAvailable)
        self.isEnrolled = try container.decode(Bool.self,
                                          forKey: .isEnrolled)
        
        self.averageMonthlyBill = try container.decode(Double.self,
                                                  forKey: .averageMonthlyBill)
        self.budgetBill = try container.decodeIfPresent(Double.self,
                                          forKey: .budgetBill)
        self.budgetBillDifference = try container.decodeIfPresent(Double.self,
                                                    forKey: .budgetBillDifference)
        self.budgetBillBalance = try container.decodeIfPresent(Double.self,
                                                 forKey: .budgetBillBalance)
        self.budgetBillPayoff = try container.decodeIfPresent(Double.self,
                                                forKey: .budgetBillPayoff)
        
        self.programStatusCode = try container.decode(String.self,
                                                 forKey: .programStatusCode)
        self.programCode = try container.decode(String.self,
                                           forKey: .programCode)
        
        self.programStartDate = try container.decode(Date.self,
                                                forKey: .programStartDate)
    }
}
