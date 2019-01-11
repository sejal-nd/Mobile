//
//  MaintenanceInitExtensions.swift
//  Mobile
//
//  Created by Samuel Francis on 5/8/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

extension Maintenance {
    init(all: Bool = false,
         home: Bool = false,
         bill: Bool = false,
         outage: Bool = false,
         alert: Bool = false,
         usage: Bool = false,
         storm: Bool = false) {
        
        assert(Environment.shared.environmentName == .aut,
               "init only available for tests")
        
        let map: [String: Any] = [
            "all": all,
            "home": home,
            "bill": bill,
            "outage": outage,
            "alert": alert,
            "usage": usage,
            "storm": storm
        ]
        
        self = Maintenance.from(map as NSDictionary)!
    }
}
