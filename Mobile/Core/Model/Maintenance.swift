//
//  MaintenanceStatus.swift
//  Mobile
//
//  Created by Constantin Koehler on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct Maintenance: Mappable {
    let maintenanceStatus: MaintenanceStatusResponse
    
    init(map: Mapper) throws {
        maintenanceStatus = try map.from("status")
    }
    
    var getIsOutage: Bool {
        return maintenanceStatus.allStatus!
    }
 
    
}

struct MaintenanceStatusResponse: Mappable {
    let allStatus: Bool?
    let homeStatus: Bool?
    let billStatus: Bool?
    let alertStatus: Bool?
    
    init(map: Mapper) throws {
        allStatus = map.optionalFrom("ALL")
        homeStatus = map.optionalFrom("HOME")
        billStatus = map.optionalFrom("OUTAGE")
        alertStatus = map.optionalFrom("ALERTS")
    }
}

