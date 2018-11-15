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
    
    init(map: Mapper) throws {
        allStatus = map.optionalFrom("all") ?? false
        homeStatus = map.optionalFrom("home") ?? false
        billStatus = map.optionalFrom("bill") ?? false
        outageStatus = map.optionalFrom("outage") ?? false
        alertStatus = map.optionalFrom("alerts") ?? false
        usageStatus = map.optionalFrom("usage") ?? false
        
        // Storm mode is not in the October release, so keep it always false for now.
        // Uncomment other code while testing.
        stormModeStatus = false//map.optionalFrom("storm") ?? false
        //stormModeStatus = arc4random_uniform(5) != 0
    }
    
}
