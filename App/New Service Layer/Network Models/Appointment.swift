//
//  Appointment.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/29/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct Appointment: Decodable {
    public var id: String
    public var type: String
    public var typeID: String
    public var status: String
    public var statusID: String
    public var completionComments: Date?
    public var createDate: Date?
    public var lastAmendDate: Date?
    public var startDate: Date?
    public var timeSlot: String?
    public var stopDate: Date?
}


// Legacy Logic
extension Appointment {
    enum Status: String {
        case scheduled = "Confirmed"
        case onOurWay = "On Our Way"
        case enRoute = "En Route"
        case inProgress = "In Progress"
        case complete = "Complete"
        case canceled = "Cancelled"
        case none
    }
    
    enum Timeslot {
        case am
        case pm
        case pmSaturday
        case anytime
                
        var displayString: String {
            switch self {
            case .am:
                return "8AM - 12PM"
            case .pm:
                return "12PM - 5PM"
            case .pmSaturday:
                return "12PM - 3PM"
            case .anytime:
                return "8AM - 2PM"
            }
        }
        
        var formattedEndHour: String {
            switch self {
            case .am:
                return "12PM"
            case .pm:
                return "5PM"
            case .pmSaturday:
                return "3PM"
            case .anytime:
                return "2PM"
            }
        }
    }

    var date: Date {
        return startDate ?? Date(timeIntervalSince1970: 0)
    }
    
    var timeslot: Timeslot {
        let components = Calendar.opCo.dateComponents([.weekday], from: startDate ?? Date())
        if timeSlot == "PM" && components.weekday == 7 {
            return .pmSaturday
        } else if timeSlot == "AM" {
            return .am
        } else if timeSlot == "PM" {
            return .pm
        }
        return .anytime
    }
    
    var startTime: Date? {
        switch timeslot {
        case .am:
            return Calendar.opCo.date(bySettingHour: 8, minute: 0, second: 0, of: startDate ?? Date())
        case .pm, .pmSaturday:
            return Calendar.opCo.date(bySettingHour: 12, minute: 0, second: 0, of: startDate ?? Date())
        case .anytime:
            return Calendar.opCo.date(bySettingHour: 8, minute: 0, second: 0, of: startDate ?? Date())
        }
    }

    var endTime: Date? {
        switch timeslot {
        case .am:
            return Calendar.opCo.date(bySettingHour: 12, minute: 0, second: 0, of: startDate ?? Date())
        case .pm:
            return Calendar.opCo.date(bySettingHour: 17, minute: 0, second: 0, of: startDate ?? Date())
        case .pmSaturday:
            return Calendar.opCo.date(bySettingHour: 15, minute: 0, second: 0, of: startDate ?? Date())
        case .anytime:
            return Calendar.opCo.date(bySettingHour: 14, minute: 0, second: 0, of: startDate ?? Date())
        }
    }
    
    var statusType: Status {
        return Status(rawValue: status) ?? .none
    }
}
