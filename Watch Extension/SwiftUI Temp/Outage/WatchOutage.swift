//
//  WatchOutage.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

struct WatchOutage: Identifiable {
    init(id: UUID = UUID(),
         isPowerOn: Bool,
         estimatedRestoration: String? = nil,
         outageStatus: OutageStatus? = nil) {
        self.id = id
        self.isPowerOn = isPowerOn
        self.estimatedRestoration = estimatedRestoration
        self.outageStatus = outageStatus
    }
    
    init(outageStatus: OutageStatus) {
        self.isPowerOn = !outageStatus.isActiveOutage
        if let estimatedRestorationDate = outageStatus.estimatedRestorationDate {
            self.estimatedRestoration = DateFormatter.outageOpcoDateFormatter.string(from: estimatedRestorationDate)
        }
        self.outageStatus = outageStatus
    }
    
    var id: UUID = UUID()
    let isPowerOn: Bool
    var estimatedRestoration: String? = nil
    var outageStatus: OutageStatus? = nil
}

extension WatchOutage: Equatable {
    static func == (lhs: WatchOutage, rhs: WatchOutage) -> Bool {
        lhs.id == rhs.id
    }
}
