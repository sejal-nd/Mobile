//
//  MaintenanceStatus.swift
//  Mobile
//
//  Created by Constantin Koehler on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct Maintenance: Mappable {
    let allStatus: Bool
    let homeStatus: Bool
    let billStatus: Bool
    let outageStatus: Bool
    let alertStatus: Bool
    let usageStatus: Bool
    let stormModeStatus: Bool
    
    let allMessage: String?
    
    init(map: Mapper) throws {
        allStatus = (map.optionalFrom("all") ?? false) || (map.optionalFrom("ios.all") ?? false)
        homeStatus = map.optionalFrom("home") ?? false || (map.optionalFrom("ios.home") ?? false)
        billStatus = map.optionalFrom("bill") ?? false || (map.optionalFrom("ios.bill") ?? false)
        outageStatus = map.optionalFrom("outage") ?? false || (map.optionalFrom("ios.outage") ?? false)
        alertStatus = map.optionalFrom("alerts") ?? false || (map.optionalFrom("ios.alerts") ?? false)
        usageStatus = map.optionalFrom("usage") ?? false || (map.optionalFrom("ios.usage") ?? false)
        
        stormModeStatus = map.optionalFrom("storm") ?? false // Real Storm Mode value
        //stormModeStatus = true // Force Storm Mode
        //stormModeStatus = Int.random(in: 1...5) != 1 // 1 in 5 chance to test exiting Storm Mode
        
        allMessage = map.optionalFrom("ios.message") ?? map.optionalFrom("message")
    }
    
}
