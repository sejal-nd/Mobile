//
//  MockAppState.swift
//  Mobile
//
//  Created by Samuel Francis on 1/31/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

struct MockAppState {
    static var current = MockAppState()
    static let `default` = MockAppState()
    
    let maintenanceKey: MockDataKey
    let opCoUpdatesKey: MockDataKey
    let hasNetworkConnection: Bool
    
    init(maintenanceKey: MockDataKey = .default,
         opCoUpdatesKey: MockDataKey = .default,
         hasNetworkConnection: Bool = true) {
        self.maintenanceKey = maintenanceKey
        self.opCoUpdatesKey = opCoUpdatesKey
        self.hasNetworkConnection = hasNetworkConnection
    }
}
