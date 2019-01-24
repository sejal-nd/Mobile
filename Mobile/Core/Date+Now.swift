//
//  Date+Now.swift
//  Mobile
//
//  Created by Samuel Francis on 1/24/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

extension Date {
    /// The current system time. Always returns the same value for test builds.
    /// Always use `Date.now`. `Date()` will break tests because of time-sensitive mock data.
    static var now: Date {
        switch Environment.shared.environmentName {
        case .dev, .test, .stage, .prod:
            return Date()
        case .aut:
            // All dates in mock data should be set relative to this date (1/1/2019, 00:00:00 OpCo Time)
            // If this date is changed, mock data must be updated
            return Calendar.opCo.date(from: DateComponents(year: 2019))!
        }
    }

}
