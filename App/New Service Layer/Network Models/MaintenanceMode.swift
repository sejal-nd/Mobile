//
//  MaintenanceMode.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct MaintenanceMode: Decodable {
    public var all = false
    public var bill = false
    public var alert = false
    public var outage = false
    public var usage = false
    public var home = false
    public var storm = false
    public var message = "The \(Environment.shared.opco.displayString) App is currently unavailable due to maintenance."
    
    enum CodingKeys: String, CodingKey {
        case all = "all"
        case bill = "bill"
        case alert = "alert"
        case outage = "outage"
        case usage = "usage"
        case home = "home"
        case storm = "storm"
        case message = "message"
    }
}
