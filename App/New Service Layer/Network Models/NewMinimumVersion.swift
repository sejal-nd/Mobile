//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewVersion: Decodable {
    public var min = "0.0.0"
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case iOS = "ios"
        case min = "minVersion"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        let iOSContainer = try data.nestedContainer(keyedBy: CodingKeys.self,
                                                    forKey: .iOS)
        self.min = try iOSContainer.decode(String.self,
                                           forKey: .min)
    }
}
