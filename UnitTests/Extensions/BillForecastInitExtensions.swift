//
//  BillForecastInitExtensions.swift
//  Mobile
//
//  Created by Marc Shilling on 2/21/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension BillForecastResult {
    init() {
        self.gas = BillForecast(meterType: "GAS")
        self.electric = BillForecast(meterType: "ELEC")
    }
    
    init(gas: BillForecast? = nil,
         electric: BillForecast? = nil) {
        if Environment.shared.environmentName != .aut {
            fatalError("init only available for tests")
        }
        
        var dictionaries = [[String: Any]]()
        if let gasJSON = gas?.toJSON() {
            dictionaries.append(gasJSON)
        }
        
        if let elecJSON = electric?.toJSON() {
            dictionaries.append(elecJSON)
        }
        
        self = try! BillForecastResult(dictionaries: dictionaries)
    }
}

extension BillForecast {

    init(errorMessage: String? = nil,
         billingStartDate: String? = nil, // Pass in yyyy-MM-dd format
         billingEndDate: String? = nil, // Pass in yyyy-MM-dd format
         toDateUsage: Double = 100,
         toDateCost: Double = 20,
         projectedUsage: Double = 500,
         projectedCost: Double = 100,
         meterType: String) {
        
        assert(Environment.shared.environmentName == .aut, "init only available for tests")
        
        var map = [String: Any]()
        map["errorMessage"] = errorMessage
        map["billingStartDate"] = billingStartDate
        map["billingEndDate"] = billingEndDate
        map["toDateUsage"] = toDateUsage
        map["toDateCost"] = toDateCost
        map["projectedUsage"] = projectedUsage
        map["projectedCost"] = projectedCost
        map["utilityAccountDTO"] = ["meterType": meterType]
        
        self = BillForecast.from(map as NSDictionary)!
    }
    
    func toJSON() -> [String : Any] {
        var map = [String: Any]()
        map["errorMessage"] = errorMessage
        if let startDate = billingStartDate {
            map["billingStartDate"] = DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: startDate)
        }
        
        if let endDate = billingEndDate {
            map["billingEndDate"] = DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: endDate)
        }
        
        map["toDateUsage"] = toDateUsage
        map["toDateCost"] = toDateCost
        map["projectedUsage"] = projectedUsage
        map["projectedCost"] = projectedCost
        map["utilityAccountDTO"] = ["meterType": meterType]
        return map
    }
}
