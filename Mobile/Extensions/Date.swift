//
//  Date.swift
//  Mobile
//
//  Created by Sam Francis on 5/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

extension Date {
    @nonobjc var MMddyyyyString: String {
        return DateFormatter.MMddyyyyFormatter.string(from: self)
    }
    
    @nonobjc var mmDdYyyyString: String {
        return DateFormatter.mmDdYyyyFormatter.string(from: self)
    }
    
    @nonobjc var yyyyMMddString: String {
        return DateFormatter.yyyyMMddFormatter.string(from: self)
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
    
    @nonobjc var dayMonthDayString: String {
        return DateFormatter.dayMonthDayFormatter.string(from: self) +
            ordinal(forCalendar: DateFormatter.dayMonthDayFormatter.calendar)
    }
    
    @nonobjc var monthDayOrdinalString: String {
        return DateFormatter.monthDayFormatter.string(from: self) +
            ordinal(forCalendar: DateFormatter.monthDayFormatter.calendar)
    }
    
    @nonobjc var hourAmPmString: String {
        var date = self
        let minutes = Calendar.current.component(.minute, from: date)
        if minutes >= 30, let adjustedDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) {
            date = adjustedDate
        }
        return DateFormatter.hourAmPmFormatter.string(from: date)
    }
        
    @nonobjc var apiFormatString: String {
        return DateFormatter.apiFormatter.string(from: self)
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
    
    func ordinal(forCalendar calendar: Calendar) -> String {
        switch calendar.component(.day, from: self) {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

extension DateFormatter {
    @nonobjc static let yyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let MMyyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMyyyy"
        return dateFormatter
    }()
    
    @nonobjc static let HHmmFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    @nonobjc static let hmmaFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }()
    
    @nonobjc static let yyyyMMddTHHmmssZFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()
    
    @nonobjc static let yyyyMMddTHHmmssSSSFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter
    }()
    
    @nonobjc static let yyyyMMddFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    @nonobjc static let yyyyMMddTHHmmssZZZZZFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()
    
    @nonobjc static let MMddyyyyFormatter: DateFormatter = { // Billing History Item
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter
    }()

    @nonobjc static let MMddyyyyHHmmFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm"
        return dateFormatter
    }()
    
    @nonobjc static let mmDdYyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let shortMonthAndDayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter
    }()
    
    @nonobjc static let fullMonthAndDayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMMM dd"
        return dateFormatter
    }()
    
    @nonobjc static let fullMonthDayAndYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let shortMonthDayAndYearFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let hourAmPmFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "ha"
        return dateFormatter
    }()
        
    @nonobjc static let apiFormatterGMT: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .gmt
        dateFormatter.timeZone = .gmt
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    @nonobjc static let apiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    @nonobjc static let noonApiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd'T'12:00:00"
        return dateFormatter
    }()
    
    @nonobjc static let dayMonthDayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "EEEE, MMM d"
        return dateFormatter
    }()
    
    @nonobjc static let monthDayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter
    }()
    
    @nonobjc static let outageOpcoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .opCo
        formatter.timeZone = .opCo
        switch Environment.shared.opco {
        case .bge:
            formatter.dateFormat = "MM/dd/yyyy hh:mm a"
        case .comEd:
            formatter.dateFormat = "hh:mm a 'on' M/dd/yyyy"
        case .peco:
            formatter.dateFormat = "h:mm a zz 'on' M/dd/yyyy"
        }
        return formatter
    }()
}

extension String {
    @nonobjc var apiFormatDate: Date? {
        return DateFormatter.apiFormatter.date(from: self)
    }
}

extension Calendar {
    static let opCo: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .opCo
        return calendar
    }()
    
    static let gmt: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
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
        switch Environment.shared.opco {
        case .bge, .peco :
            return TimeZone(identifier: "America/New_York")!
        case .comEd:
            return TimeZone(identifier: "America/Chicago")!
        }
    }()
    
    static let gmt = TimeZone(identifier: "GMT")!
}


