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
    
    let maintenanceKey: String
    let hasNetworkConnection: Bool
    
    init(maintenanceKey: MockDataKey = .default, hasNetworkConnection: Bool = true) {
        self.maintenanceKey = maintenanceKey.rawValue
        self.hasNetworkConnection = hasNetworkConnection
    }
}
