//
//  MaintenanceInitExtensions.swift
//  Mobile
//
//  Created by Samuel Francis on 5/8/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

extension Maintenance {
    init(all: Bool = false,
         home: Bool = false,
         bill: Bool = false,
         outage: Bool = false,
         alert: Bool = false,
         storm: Bool = false) {
        
        assert(Environment.shared.environmentName == .aut,
               "init only available for tests")
        
        allStatus = all
        homeStatus = home
        billStatus = bill
        outageStatus = outage
        alertStatus = alert
        stormModeStatus = storm
    }
}
