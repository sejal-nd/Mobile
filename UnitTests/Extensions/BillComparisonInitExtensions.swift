//
//  BillComparisonInitExtensions.swift
//  BGE
//
//  Created by Marc Shilling on 2/21/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

extension BillComparison {
    
    init(meterUnit: String = "KWH",
         currencySymbol: String = "$",
         temperatureUnit: String = "FAHRENHEIT",
         reference: UsageBillPeriod = UsageBillPeriod(),
         compared: UsageBillPeriod = UsageBillPeriod(),
         billPeriodCostDifference: Double = 0,
         weatherCostDifference: Double = 0,
         otherCostDifference: Double = 0) {
        
        if Environment.shared.environmentName != .aut {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["meterUnit"] = meterUnit
        map["currencySymbol"] = currencySymbol
        map["temperatureUnit"] = temperatureUnit
        map["reference"] = reference.toJSON()
        map["compared"] = compared.toJSON()
        
        self = BillComparison.from(map as NSDictionary)!
        self.billPeriodCostDifference = billPeriodCostDifference
        self.weatherCostDifference = weatherCostDifference
        self.otherCostDifference = otherCostDifference
    }
}

extension UsageBillPeriod: JSONEncodable {
    
    init(charges: Double = 100,
         usage: Double = 100,
         startDate: String = "2017-08-01", // Pass in yyyy-MM-dd format
         endDate: String? = "2017-09-01", // Pass in yyyy-MM-dd format
         averageTemperature: Double = 72) {
        
        if Environment.shared.environmentName != .aut {
            fatalError("init only available for tests")
        }
        
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
            "averageTemperature": averageTemperature,
        ]
    }
}

