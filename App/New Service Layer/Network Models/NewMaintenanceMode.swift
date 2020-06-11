//
//  NewMaintenanceMode.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewMaintenanceMode: Decodable {
    public var all = false
    public var bill = false
    public var alert = false
    public var outage = false
    public var home = false
    public var storm = false
    public var message = "The \(Environment.shared.opco.displayString) App is currently unavailable due to maintenance."
    
    enum CodingKeys: String, CodingKey {
        case all = "all"
        case bill = "bill"
        case alert = "alert"
        case outage = "outage"
        case home = "home"
        case storm = "storm"
        case message = "message"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.all = try container.decode(Bool.self,
                                        forKey: .all)
        self.bill = try container.decode(Bool.self,
                                         forKey: .bill)
        self.alert = try container.decodeIfPresent(Bool.self,
                                                   forKey: .alert) ?? false
        self.outage = try container.decode(Bool.self,
                                           forKey: .outage)
        self.home = try container.decode(Bool.self,
                                         forKey: .home)
        self.storm = try container.decode(Bool.self,
                                          forKey: .storm)
        self.message = try container.decode(String.self,
                                            forKey: .message)
    }
}
