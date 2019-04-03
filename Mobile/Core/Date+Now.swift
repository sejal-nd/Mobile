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
    /// Always use `Date.now`. `Date()` will break tests due to time-sensitive mock data.
    static var now: Date {
        switch Environment.shared.environmentName {
        case .dev, .test, .stage, .prodbeta, .prod:
            return Date()
        case .aut:
            // All dates in mock data should be set relative to this date (1/1/2019, 00:00:00 OpCo Time)
            // If this date is changed, mock data must be updated
            return Calendar.opCo.date(from: DateComponents(year: 2019))!
        }
    }
    
    /// Always use instead of `Calendar.isDateInToday`, which breaks tests due to time-sensitive mock data.
    func isInToday(calendar: Calendar) -> Bool {
        return calendar.isDate(self, inSameDayAs: .now)
    }
    
    /// Always use instead of `Calendar.isDateInTomorrow`, which breaks tests due to time-sensitive mock data.
    func isInTomorrow(calendar: Calendar) -> Bool {
        guard let tomorrow = calendar.date(byAdding: DateComponents(day: 1), to: .now) else {
            return false
        }
        
        return calendar.isDate(self, inSameDayAs: tomorrow)
    }
    
    /// Always use instead of `Calendar.isDateInYesterday`, which breaks tests due to time-sensitive mock data.
    func isInYesterday(calendar: Calendar) -> Bool {
        guard let yesterday = calendar.date(byAdding: DateComponents(day: -1), to: .now) else {
            return false
        }
        
        return calendar.isDate(self, inSameDayAs: yesterday)
    }
}
