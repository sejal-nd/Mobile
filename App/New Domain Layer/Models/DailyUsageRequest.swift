//
//  DailyUsageRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 6/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct DailyUsageRequest: Encodable {
    var startDate: String
    var endDate: String
    var fuelType: String
    var intervalType: String
    
    init(startDate: Date, endDate: Date, gas: Bool) {
        self.startDate = startDate.yyyyMMddString
        self.endDate = endDate.yyyyMMddString
        self.fuelType = gas ? "GAS" : "ELECTRICITY"
        self.intervalType = "day"
    }
}
