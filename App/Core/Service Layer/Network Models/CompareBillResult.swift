//
//  NewSchedulePaymentResult.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct CompareBillResult: Decodable {
    public var meterUnit: String
    public var currencySymbol: String
    public var temperatureUnit: String
    
    public var referenceBill: Bill?
    public var comparedBill: Bill?
    public var billAnalysisResults: [BillAnalysisResult]
    
    public var billPeriodCostDifference = 0.0
    public var weatherCostDifference = 0.0
    public var otherCostDifference = 0.0
    
    enum CodingKeys: String, CodingKey {
        case meterUnit = "meterUnit"
        case currencySymbol = "currencySymbol"
        case temperatureUnit = "temperatureUnit"
        case referenceBill = "reference"
        case comparedBill = "compared"
        case billAnalysisResults = "analysisResults"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.meterUnit = try container.decode(String.self,
                                         forKey: .meterUnit)
        self.currencySymbol = try container.decode(String.self,
                                              forKey: .currencySymbol)
        self.temperatureUnit = try container.decode(String.self,
                                               forKey: .temperatureUnit)
        
        self.referenceBill = try container.decodeIfPresent(Bill.self,
                                             forKey: .referenceBill)
        self.comparedBill = try container.decodeIfPresent(Bill.self,
                                            forKey: .comparedBill)
        
        self.billAnalysisResults = try container.decodeIfPresent([BillAnalysisResult].self,
                                                   forKey: .billAnalysisResults) ?? []
        
        for result in billAnalysisResults {
            if result.analysisName == "NUM_DAYS" {
                billPeriodCostDifference = result.costDifferenceExplained
            } else if result.analysisName == "WEATHER" {
                weatherCostDifference = result.costDifferenceExplained
            } else if result.analysisName == "OTHER" {
                otherCostDifference = result.costDifferenceExplained
            }
        }
    }
}

public struct Bill: Decodable {
    public var charges: Double
    public var usage: Double
    public var startDate: Date
    public var endDate: Date
    public var averageTemperature: Double?
    public var ratePlan: String?
}

public struct BillAnalysisResult: Decodable {
    public var analysisName: String
    public var costDifferenceExplained: Double
}
