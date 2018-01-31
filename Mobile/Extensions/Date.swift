//
//  Date.swift
//  Mobile
//
//  Created by Sam Francis on 5/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension Date {
    @nonobjc var mmDdYyyyString: String {
        return DateFormatter.mmDdYyyyFormatter.string(from: self)
    }
    
    @nonobjc var shortMonthAndDayString: String {
        return DateFormatter.shortMonthAndDayFormatter.string(from: self)
    }
    
    @nonobjc var fullMonthAndDayString: String {
        return DateFormatter.fullMonthAndDayFormatter.string(from: self)
    }
    
    @nonobjc var fullMonthDayAndYearString: String {
        return DateFormatter.fullMonthDayAndYearFormatter.string(from: self)
    }
    
    @nonobjc var shortMonthDayAndYearString: String {
        return DateFormatter.shortMonthDayAndYearFormatter.string(from: self)
    }
    
    @nonobjc var hourAmPmString: String {
        return DateFormatter.hourAmPmFormatter.string(from: self)
    }
    
    @nonobjc var apiFormatString: String {
        return DateFormatter.apiFormatter.string(from: self)
    }
    
    @nonobjc var apiFormatDate: Date {
        let dateString = DateFormatter.apiFormatter.string(from: self)
        return dateString.apiFormatDate
    }
    
    @nonobjc var localizedGreeting: String {
        let components = Calendar.current.dateComponents([.hour], from: self)
        guard let hour = components.hour else { return "Greetings" }
        
        if 4 ... 11 ~= hour {
            return NSLocalizedString("Good Morning", comment: "")
        } else if 11 ... 15 ~= hour {
            return NSLocalizedString("Good Afternoon", comment: "")
        } else {
            return NSLocalizedString("Good Evening", comment: "")
        }
        
    }
    
    @nonobjc var paymentFormatString: String {
        if Calendar.current.isDateInToday(self) {
            return DateFormatter.apiFormatterGMT.string(from: self)
        } else {
            return DateFormatter.noonApiFormatter.string(from: self)
        }
    }
    
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        let currentCalendar = Calendar.opCo
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        return end - start
    }
}

extension DateFormatter {
    @nonobjc static let mmDdYyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let shortMonthAndDayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter
    }()
    
    @nonobjc static let fullMonthAndDayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMMM dd"
        return dateFormatter
    }()
    
    @nonobjc static let fullMonthDayAndYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let shortMonthDayAndYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let hourAmPmFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "ha"
        return dateFormatter
    }()
    
    @nonobjc static let apiFormatterGMT: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .gmt
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    @nonobjc static let apiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    @nonobjc static let noonApiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'12:00:00"
        return dateFormatter
    }()
}

extension String {
    @nonobjc var mmDdYyyyDate: Date {
        return DateFormatter.mmDdYyyyFormatter.date(from: self)!
    }
    
    @nonobjc var apiFormatDate: Date {
        return DateFormatter.apiFormatter.date(from: self)!
    }

}

extension Calendar {
    static let opCo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .opCo
        return calendar
    }()
    
    func endOfDay(for date: Date) -> Date {
        let startOfDay = Calendar.opCo.startOfDay(for: date)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.opCo.date(byAdding: components, to: startOfDay)!
    }
}

extension TimeZone {
    static let opCo: TimeZone = {
        switch Environment.sharedInstance.opco {
        case .bge, .peco :
            return TimeZone(identifier: "America/New_York")!
        case .comEd:
            return TimeZone(identifier: "America/Chicago")!
        }
    }()
    
    static let gmt = TimeZone(identifier: "GMT")!
}


