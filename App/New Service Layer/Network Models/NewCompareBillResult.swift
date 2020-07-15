//
//  NewSchedulePaymentResult.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewCompareBillResult: Decodable {
    public var meterUnit: String
    public var currencySymbol: String
    public var temperatureUnit: String
    
    public var referenceBill: NewBill?
    public var comparedBill: NewBill?
    public var billAnalysisResults: [NewBillAnalysisResult]
    
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
        
        self.referenceBill = try container.decodeIfPresent(NewBill.self,
                                             forKey: .referenceBill)
        self.comparedBill = try container.decodeIfPresent(NewBill.self,
                                            forKey: .comparedBill)
        
        self.billAnalysisResults = try container.decodeIfPresent([NewBillAnalysisResult].self,
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

public struct NewBill: Decodable {
    public var charges: Double
    public var usage: Double
    public var startDate: Date
    public var endDate: Date
    public var averageTemperature: Double?
    public var ratePlan: String?
}

public struct NewBillAnalysisResult: Decodable {
    public var analysisName: String
    public var costDifferenceExplained: Double
}

//
//"data": {
//    "meterUnit": "KWH",
//    "currencySymbol": "$",
//    "temperatureUnit": "FAHRENHEIT",
//    "analysisResults": [
//    {
//    "analysisName": "NUM_DAYS",
//    "costDifferenceExplained": 8.4
//    },
//    {
//    "analysisName": "WEATHER",
//    "costDifferenceExplained": -7.79
//    },
//    {
//    "analysisName": "OTHER",
//    "costDifferenceExplained": -33.27
//    }
//    ],
//    "reference": {
//        "charges": 89.15,
//        "usage": 658,
//        "startDate": "2020-01-31",
//        "endDate": "2020-03-01",
//        "averageTemperature": 41.9,
//        "ratePlan": "R_PTR"
//    },
//    "compared": {
//        "charges": 121.81,
//        "usage": 915,
//        "startDate": "2019-01-31",
//        "endDate": "2019-02-28",
//        "averageTemperature": 36.6,
//        "ratePlan": "R_PTR"
//    }
//}
