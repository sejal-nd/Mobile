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
            return DateFormatter.apiFormatter.string(from: self)
        } else {
            return DateFormatter.noonApiFormatter.string(from: self)
        }
    }
}

extension DateFormatter {
    @nonobjc static let mmDdYyyyFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter
    }()
    
    @nonobjc static let apiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")!
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }()
    
    @nonobjc static let noonApiFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
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
    static let opCoTime: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        switch Environment.sharedInstance.opco {
        case .bge, .peco :
            calendar.timeZone = TimeZone(identifier: "America/New_York")!
        case .comEd:
            calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        }
        return calendar
    }()
}


