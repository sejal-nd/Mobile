//
//  NewUsageData.swift
//  Mobile
//
//  Created by Cody Dillon on 6/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct DailyUsageData: Decodable {
    var dailyUsage: [DailyUsage]
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
        var streamsArray = try usageData.nestedUnkeyedContainer(forKey: .streams)
        let streamsContainer = try streamsArray.nestedContainer(keyedBy: CodingKeys.self)
        let unit = try usageData.decode(String.self, forKey: .unit)
        
        if unit == "KWH" {
            self.unit = "kWh"
        } else if unit == "THERM" {
            self.unit = "therms"
        } else {
            self.unit = unit
        }
        
        self.dailyUsage = try streamsContainer.decode([DailyUsage].self, forKey: .intervals).sorted(by: { $0.date > $1.date })
    }
}
