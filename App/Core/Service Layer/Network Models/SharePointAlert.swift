//
//  SharePointAlert.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct SharePointAlert: Decodable {
    public var alerts: [Alert]
    
    enum CodingKeys: String, CodingKey {
        case data = "d"
        case alerts = "results"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.alerts = try data.decode([Alert].self,
                                      forKey: .alerts)
    }
}
