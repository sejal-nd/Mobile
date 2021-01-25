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
    public var alerts = false
    public var message = "The \(Environment.shared.opco.displayString) App is currently unavailable due to maintenance."
    
    enum CodingKeys: String, CodingKey {
        case iOS = "ios"
        case all = "all"
        case bill = "bill"
        case outage = "outage"
        case usage = "usage"
        case home = "home"
        case alerts = "alerts"
        case storm = "storm"
        case message = "message"
    }
    
    public init(from decoder: Decoder) throws {
        
        // Prodbeta builds should ignore any maintenance response
        if Environment.shared.environmentName == .rc {
            return
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let iosContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                         forKey: .iOS)
        
        let iosAll = try iosContainer.decode(Bool.self, forKey: .all)
        let iosBill = try iosContainer.decode(Bool.self, forKey: .bill)
        let iosOutage = try iosContainer.decode(Bool.self, forKey: .outage)
        let iosUsage = try iosContainer.decode(Bool.self, forKey: .usage)
        let iosHome = try iosContainer.decode(Bool.self, forKey: .home)
        let iosStorm = try iosContainer.decodeIfPresent(Bool.self, forKey: .storm) ?? false
        
        let rootAll = try container.decode(Bool.self, forKey: .all)
        let rootBill = try container.decode(Bool.self, forKey: .bill)
        let rootOutage = try container.decode(Bool.self, forKey: .outage)
        let rootUsage = try container.decodeIfPresent(Bool.self, forKey: .usage) ?? false
        let rootHome = try container.decode(Bool.self, forKey: .home)
        let rootStorm = try container.decode(Bool.self, forKey: .storm)
        self.alerts = try container.decode(Bool.self, forKey: .alerts)
        
        self.all = iosAll || rootAll
        self.bill = iosBill || rootBill
        self.outage = iosOutage || rootOutage
        self.usage = iosUsage || rootUsage
        self.home = iosHome || rootHome
        self.storm = iosStorm || rootStorm
        self.message = try iosContainer.decode(String.self, forKey: .message)
    }
    
    public init() {
        
    }
}
