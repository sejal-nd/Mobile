//
//  Weekday.swift
//  Mobile
//
//  Created by Marc Shilling on 11/5/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    init?(fromString string: String) {
        switch string {
        case "Sunday":
            self = .sunday
        case "Monday":
            self = .monday
        case "Tuesday":
            self = .tuesday
        case "Wednesday":
            self = .wednesday
        case "Thursday":
            self = .thursday
        case "Friday":
            self = .friday
        case "Saturday":
            self = .saturday
        default:
            return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .sunday:
            return "Sunday"
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        }
    }
    
    var abbreviationString: String {
        switch self {
        case .sunday:
            return "S"
        case .monday:
            return "M"
        case .tuesday:
            return "T"
        case .wednesday:
            return "W"
        case .thursday:
            return "Th"
        case .friday:
            return "F"
        case .saturday:
            return "S"
        }
    }
    
}
