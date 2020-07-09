//
//  AnonOutageStatus.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AnonOutageStatus: Decodable {
    var statuses = [OutageStatus]()
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.statuses = try container.decode([OutageStatus].self)
    }
}
