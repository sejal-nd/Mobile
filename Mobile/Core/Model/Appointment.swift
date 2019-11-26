//
//  Appointment.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct Appointment: Mappable, Equatable {
    
    enum Status: String {
        case scheduled = "Confirmed"
        case enRoute = "En Route"
        case inProgress = "In Progress"
        case complete = "Complete"
        case canceled = "Cancelled"
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
    }
    
    let id: String
    let date: Date
    let stopDate: Date
    let status: Status
    private let timeslotString: String?

    init(map: Mapper) throws {
        id = try map.from("id")
        date = try map.from("startDate", transformation: DateParser().extractDate)
        stopDate = try map.from("stopDate", transformation: DateParser().extractDate)
        timeslotString = map.optionalFrom("timeSlot")
        status = try map.from("status") { object in
            guard let string = object as? String, let status = Status(rawValue: string) else {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
            }
            return status
        }
    }
    
    var timeslot: Timeslot {
        let components = Calendar.opCo.dateComponents([.weekday], from: date)
        if timeslotString == "PM" && components.weekday == 7 {
            return .pmSaturday
        } else if timeslotString == "AM" {
            return .am
        } else if timeslotString == "PM" {
            return .pm
        }
        return .anytime
    }
    
    var startTime: Date {
        switch timeslot {
        case .am:
            return Calendar.opCo.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        case .pm, .pmSaturday:
            return Calendar.opCo.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        case .anytime:
            return Calendar.opCo.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        }
    }

    var endTime: Date {
        switch timeslot {
        case .am:
            return Calendar.opCo.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        case .pm:
            return Calendar.opCo.date(bySettingHour: 17, minute: 0, second: 0, of: date)!
        case .pmSaturday:
            return Calendar.opCo.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
        case .anytime:
            return Calendar.opCo.date(bySettingHour: 14, minute: 0, second: 0, of: date)!
        }
    }
}
