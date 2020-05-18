//
//  HomeProfileLoadNew.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct HomeProfileLoadNew: Decodable {
    public var customerId: Int
    public var dwellingType: String
    public var squareFeet: Int
    public var heatType: String
    public var numberOfAdults: Int
    public var numberOfChildren: Int
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        
        case customerId = "customerId"
        case dwellingType = "dwellingType"
        case squareFeet = "squareFeet"
        case heatType = "heatType"
        case numberOfAdults = "numberOfAdults"
        case numberOfChildren = "numberOfChildren"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        
        self.customerId = try data.decode(Int.self,
                                          forKey: .customerId)
        self.dwellingType = try data.decode(String.self,
                                            forKey: .dwellingType)
        self.squareFeet = try data.decode(Int.self,
                                          forKey: .squareFeet)
        self.heatType = try data.decode(String.self,
                                        forKey: .heatType)
        self.numberOfAdults = try data.decode(Int.self,
                                              forKey: .numberOfAdults)
        self.numberOfChildren = try data.decode(Int.self,
                                                forKey: .numberOfChildren)
    }
}
