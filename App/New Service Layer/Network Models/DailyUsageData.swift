//
//  NewUsageData.swift
//  Mobile
//
//  Created by Cody Dillon on 6/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct DailyUsageData: Decodable {
    var dailyUsage: [NewDailyUsage]
    var unit: String
    
    enum CodingKeys: String, CodingKey {
        case usageData
        case unit
        case streams
        case intervals
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let usageData = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .usageData)
        let streamsContainer = try usageData.nestedContainer(keyedBy: CodingKeys.self, forKey: .streams)
        var intervalsContainer = try streamsContainer.nestedUnkeyedContainer(forKey: .intervals)
        let unit = try usageData.decode(String.self, forKey: .unit)
        
        if unit == "KWH" {
            self.unit = "kWh"
        } else if unit == "THERM" {
            self.unit = "therms"
        } else {
            self.unit = unit
        }
        
        self.dailyUsage = try intervalsContainer.decode([NewDailyUsage].self)
    }
}

struct NewDailyUsage: Decodable {
    var date: Date
    var amount: Double
    
    enum CodingKeys: String, CodingKey {
        case date = "start"
        case amount = "usage"
    }
}
