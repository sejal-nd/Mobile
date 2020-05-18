//
//  NewBillForecast.swift
//  Mobile
//
//  Created by Cody Dillon on 5/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewBillForecast: Decodable {
    let errorMessage: String?
    
    // These all need to be optional because to account for the state where errorMessage is passed
    let billingStartDate: Date?
    let billingEndDate: Date?
    let calculationDate: Date?
    let toDateUsage: Double?
    let toDateCost: Double?
    let projectedUsage: Double?
    let projectedCost: Double?
    let baselineUsage: Double?
    let baselineCost: Double?
    let currencySymbol: String?
    
    let meterType: String // "ELEC" or "GAS"
    var meterUnit: String
    
    enum CodingKeys: String, CodingKey {
        case errorMessage
        case billingStartDate
        case billingEndDate
        case calculationDate
        case toDateUsage
        case toDateCost
        case projectedUsage
        case projectedCost
        case baselineUsage
        case baselineCost
        case currencySymbol
        
        case utilityAccount = "utilityAccountDTO"
        case meterType = "meterType"
        case meterUnit = "meterUnit"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        errorMessage = try container.decode(String.self, forKey: .errorMessage)
        
        billingStartDate = try container.decode(Date.self, forKey: .billingStartDate)
        billingEndDate = try container.decode(Date.self, forKey: .billingEndDate)
        calculationDate = try container.decode(Date.self, forKey: .calculationDate)
        toDateUsage = try container.decode(Double.self, forKey: .toDateUsage)
        toDateCost = try container.decode(Double.self, forKey: .toDateCost)
        projectedUsage = try container.decode(Double.self, forKey: .projectedUsage)
        projectedCost = try container.decode(Double.self, forKey: .projectedCost)
        baselineUsage = try container.decode(Double.self, forKey: .baselineUsage)
        baselineCost = try container.decode(Double.self, forKey: .baselineCost)
        currencySymbol = try container.decode(String.self, forKey: .currencySymbol)
        
        let utilityAccount = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .utilityAccount)
        meterType = try utilityAccount.decode(String.self, forKey: .meterType)
        meterUnit = try utilityAccount.decode(String.self, forKey: .meterUnit)
    }
}
