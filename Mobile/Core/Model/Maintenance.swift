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
    let alertStatus: Bool

    init(map: Mapper) throws {
        allStatus = map.optionalFrom("ALL") ?? false
        homeStatus = map.optionalFrom("HOME") ?? false
        billStatus = map.optionalFrom("OUTAGE") ?? false
        alertStatus = map.optionalFrom("ALERTS") ?? false
    }
    
}
