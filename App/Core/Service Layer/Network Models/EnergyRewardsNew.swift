//
//  SERInfoNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct EnergyRewardsNew: Decodable {
    public var energyRewards: [EnergyRewardNew]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case energyRewards = "energyRewards"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.energyRewards = try data.decode([EnergyRewardNew].self,
                                             forKey: .energyRewards)
    }
}

public struct EnergyRewardNew: Decodable {
    public var eventStart: Date
    public var eventEnd: Date
    public var baselineKWH: String
    public var actualKWH: String
    public var savingDollar: String
    public var savingKWH: String
}
