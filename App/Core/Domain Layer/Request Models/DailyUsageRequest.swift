//
//  DailyUsageRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 6/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct DailyUsageRequest: Encodable {
    var startDate: String
    var endDate: String
    var fuelType: String
    var intervalType: String
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
        case fuelType = "fuel_type"
        case intervalType = "interval_type"
    }
    
    init(startDate: Date, endDate: Date, isGas: Bool) {
        self.startDate = startDate.yyyyMMddString
        self.endDate = endDate.yyyyMMddString
        self.fuelType = isGas ? "GAS" : "ELECTRICITY"
        self.intervalType = "day"
    }
}
