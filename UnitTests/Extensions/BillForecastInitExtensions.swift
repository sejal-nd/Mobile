//
//  BillForecastInitExtensions.swift
//  Mobile
//
//  Created by Marc Shilling on 2/21/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

extension BillForecast {

    init(errorMessage: String? = nil,
         billingStartDate: String? = nil, // Pass in yyyy-MM-dd format
         billingEndDate: String? = nil, // Pass in yyyy-MM-dd format
         toDateUsage: Double = 100,
         toDateCost: Double = 20,
         projectedUsage: Double = 500,
         projectedCost: Double = 100) {
        
        if Environment.shared.environmentName != .aut {
            fatalError("init only available for tests")
        }
        
        var map = [String: Any]()
        map["errorMessage"] = errorMessage
        map["billingStartDate"] = billingStartDate
        map["billingEndDate"] = billingEndDate
        map["toDateUsage"] = toDateUsage
        map["toDateCost"] = toDateCost
        map["projectedUsage"] = projectedUsage
        map["projectedCost"] = projectedCost
        map["utilityAccountDTO"] = ["meterType": "ELEC"]
        
        self = BillForecast.from(map as NSDictionary)!
    }
         
}
