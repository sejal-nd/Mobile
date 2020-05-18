//
//  UsageTipNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct usageTipsContainer: Decodable {
    public var usageTips: [UsageTipNew]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case usageTips = "usageTips"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.usageTips = try data.decode([UsageTipNew].self,
                                                 forKey: .usageTips)
    }
}

public struct UsageTipNew: Decodable {
    public var tipName: String
    public var title: String
    public var score: Double
    public var group: String
    public var costCategory: String
    public var image: String
    public var status: Double
    public var numParticipating: String
    public var why: String
    public var shortBody: String
    public var longBody: String
    public var fuelType: [String]
    public var season: [String]
}
