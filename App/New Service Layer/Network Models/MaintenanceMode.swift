//
//  MaintenanceMode.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// todo we need to discuss are we looking for root level maintenance objects or only iOS ?
public struct MaintenanceMode: Decodable {
    public var all = false
    public var bill = false
    public var outage = false
    public var usage = false
    public var home = false
    public var storm = false
    public var message = "The \(Environment.shared.opco.displayString) App is currently unavailable due to maintenance."
    
    enum CodingKeys: String, CodingKey {
        case iOS = "ios"
        case all = "all"
        case bill = "bill"
        case outage = "outage"
        case usage = "usage"
        case home = "home"
        case storm = "storm"
        case message = "message"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let iosContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                         forKey: .iOS)
        self.all = try iosContainer.decode(Bool.self, forKey: .all)
        self.bill = try iosContainer.decode(Bool.self, forKey: .bill)
        self.outage = try iosContainer.decode(Bool.self, forKey: .outage)
        self.usage = try iosContainer.decode(Bool.self, forKey: .usage)
        self.home = try iosContainer.decode(Bool.self, forKey: .home)
        self.storm = try iosContainer.decode(Bool.self, forKey: .storm)
        self.all = try iosContainer.decode(Bool.self, forKey: .all)
        self.message = try iosContainer.decode(String.self, forKey: .message)
    }
    
    public init() {
        
    }
}
