//
//  NewMeterPingResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewMeterPingResult: Decodable {
    let pingResult: Bool
    let voltageResult: Bool
    let voltageReads: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case pingResult
        case voltageResult
        case voltageReads
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.pingResult = try data.decode(Bool.self,
                                          forKey: .pingResult)
        self.voltageResult = try data.decode(Bool.self,
                                             forKey: .voltageResult)
        self.voltageReads = try data.decode(String.self,
                                            forKey: .voltageReads)

    }
}
