//
//  AzureAlerts.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AzureAlerts: Decodable {
    public var alerts: [Alert]
    
    enum CodingKeys: String, CodingKey {
        case alerts = "mobile"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.alerts = try container.decode([Alert].self,
                                      forKey: .alerts)
    }
}
