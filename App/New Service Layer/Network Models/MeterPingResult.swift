//
//  NewMeterPingResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct MeterPingResult: Decodable {
    let pingResult: Bool
    var voltageResult = false
    let voltageReads: String?
    
    enum CodingKeys: String, CodingKey {
        case meterInfo = "meterInfo"
        case pingResult
        case voltageResult
        case voltageReads
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let meterInfoContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                               forKey: .meterInfo)
        
        self.pingResult = try meterInfoContainer.decode(Bool.self, forKey: .pingResult)
        self.voltageResult = try meterInfoContainer.decodeIfPresent(Bool.self, forKey: .voltageResult) ?? false
        self.voltageReads = try meterInfoContainer.decodeIfPresent(String.self, forKey: .voltageReads)
    }
}
