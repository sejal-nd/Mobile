//
//  BillComparison.swift
//  Mobile
//
//  Created by Marc Shilling on 10/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func extractDate(object: Any?) throws -> Date {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.date(from: dateString)!
}

struct BillComparison: Mappable {
    let meterUnit: String
    let currencySymbol: String
    let temperatureUnit: String
    let analysisResults: [AnalysisResult]
    let reference: UsageBillPeriod
    let compared: UsageBillPeriod
    
    var billPeriodCostDifference: Double = 0
    var weatherCostDifference: Double = 0
    var otherCostDifference: Double = 0
    
    init(map: Mapper) throws {
        try meterUnit = map.from("meterUnit")
        try currencySymbol = map.from("currencySymbol")
        try temperatureUnit = map.from("temperatureUnit")
        try analysisResults = map.from("analysisResults")
        try reference = map.from("reference")
        try compared = map.from("compared")
        
        // Parse out the analysis results for easier use
        for result in analysisResults {
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
    let averageTemperature: Double
    let ratePlan: String
    
    init(map: Mapper) throws {
        try charges = map.from("charges")
        try usage = map.from("usage")
        try startDate = map.from("startDate", transformation: extractDate)
        try endDate = map.from("endDate", transformation: extractDate)
        try averageTemperature = map.from("averageTemperature")
        try ratePlan = map.from("ratePlan")
    }
}
