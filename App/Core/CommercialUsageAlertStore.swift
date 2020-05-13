//
//  CommercialUsageAlertStore.swift
//  Mobile
//
//  Created by Samuel Francis on 5/10/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

class CommercialUsageAlertStore {
    
    private let cutoffDate: Date = {
        let components = DateComponents(year: 2019, month: 9, day: 29)
        return Calendar.opCo.date(from: components)!
    }()
    
    static let shared = CommercialUsageAlertStore()
    
    // Private init protects against another instance being accidentally instantiated
    private init() { }
    
    var isEligibleForAlert: Bool {
        let hasSeenAlert = UserDefaults.standard.bool(forKey: UserDefaultKeys.commercialUsageAlertSeen)
        return !hasSeenAlert && Date.now < cutoffDate
    }
    
    func hasSeenAlert() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.commercialUsageAlertSeen)
    }
    
}
