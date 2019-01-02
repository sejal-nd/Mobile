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
        allStatus = true// map.optionalFrom("all") ?? false
        homeStatus = map.optionalFrom("home") ?? false
        billStatus = map.optionalFrom("bill") ?? false
        outageStatus = map.optionalFrom("outage") ?? false
        alertStatus = map.optionalFrom("alerts") ?? false
        usageStatus = map.optionalFrom("usage") ?? false
        
        stormModeStatus = map.optionalFrom("storm") ?? false // Real Storm Mode value
        //stormModeStatus = true // Force Storm Mode
        //stormModeStatus = Int.random(in: 1...5) != 1 // 1 in 5 chance to test exiting Storm Mode
        
//        allMessage = map.optionalFrom("allMessage")
        allMessage = Bool.random() ? nil : "how now brown cow"
    }
    
}
