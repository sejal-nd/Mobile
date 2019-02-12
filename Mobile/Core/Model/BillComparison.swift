//
//  BillComparison.swift
//  Mobile
//
//  Created by Marc Shilling on 10/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct BillComparison: Mappable {
    var meterUnit: String
    let currencySymbol: String
    let temperatureUnit: String
    let reference: UsageBillPeriod?
    let compared: UsageBillPeriod?
    
    private let analysisResults: [AnalysisResult]?
    var billPeriodCostDifference: Double = 0
    var weatherCostDifference: Double = 0
    var otherCostDifference: Double = 0
    
    init(map: Mapper) throws {
        meterUnit = map.optionalFrom("meterUnit") ?? ""

        if meterUnit == "KWH" {
            meterUnit = "kWh"
        } else if meterUnit == "THERM" {
            meterUnit = "therms"
        }

        try currencySymbol = map.from("currencySymbol")
        try temperatureUnit = map.from("temperatureUnit")
        analysisResults = map.optionalFrom("analysisResults")
        reference = map.optionalFrom("reference")
        compared = map.optionalFrom("compared")
        
        // Parse out the analysis results for easier use
        if let results = analysisResults {
            for result in results {
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
    
    init(meterUnit: String = "KWH",
         currencySymbol: String = "$",
         temperatureUnit: String = "FAHRENHEIT",
         reference: UsageBillPeriod? = UsageBillPeriod(),
         compared: UsageBillPeriod? = UsageBillPeriod(),
         billPeriodCostDifference: Double = 0,
         weatherCostDifference: Double = 0,
         otherCostDifference: Double = 0) {
        
        var map = [String: Any]()
        map["meterUnit"] = meterUnit
        map["currencySymbol"] = currencySymbol
        map["temperatureUnit"] = temperatureUnit
        if let reference = reference {
            map["reference"] = reference.toJSON()
        }
        if let compared = compared {
            map["compared"] = compared.toJSON()
        }
        self = BillComparison.from(map as NSDictionary)!
        self.billPeriodCostDifference = billPeriodCostDifference
        self.weatherCostDifference = weatherCostDifference
        self.otherCostDifference = otherCostDifference
    }
}

struct AnalysisResult: Mappable {
    let analysisName: String
    let costDifferenceExplained: Double
    
    init(map: Mapper) throws {
        try analysisName = map.from("analysisName")
        try costDifferenceExplained = map.from("costDifferenceExplained")
    }
}

struct UsageBillPeriod: Mappable {
    let charges: Double
    let usage: Double
    let startDate: Date
    let endDate: Date
    let averageTemperature: Double?
    let ratePlan: String?
    
    init(map: Mapper) throws {
        try charges = map.from("charges")
        try usage = map.from("usage")
        try startDate = map.from("startDate", transformation: DateParser().extractDate)
        try endDate = map.from("endDate", transformation: DateParser().extractDate)
        averageTemperature = map.optionalFrom("averageTemperature")
        ratePlan = map.optionalFrom("ratePlan")
    }
    
    init(charges: Double = 100,
         usage: Double = 100,
         startDate: String = "2017-08-01", // Pass in yyyy-MM-dd format
        endDate: String? = "2017-09-01", // Pass in yyyy-MM-dd format
        averageTemperature: Double = 72) {
        
        var map = [String: Any]()
        map["charges"] = charges
        map["usage"] = usage
        map["startDate"] = startDate
        map["endDate"] = endDate
        map["averageTemperature"] = averageTemperature
        
        self = UsageBillPeriod.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any?] {
        return [
            "charges": charges,
            "usage": usage,
            "startDate": DateFormatter.yyyyMMddFormatter.string(from: startDate),
            "endDate": DateFormatter.yyyyMMddFormatter.string(from: endDate),
            "averageTemperature": averageTemperature
        ]
    }
}
