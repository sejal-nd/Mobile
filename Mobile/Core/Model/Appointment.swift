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
        case enRoute = "On Our Way"
        case inProgress = "In Progress"
        case complete = "Complete"
        case canceled = "Cancelled"
    }
    
    let id: String
    let startDate: Date
    let stopDate: Date
    let status: Status
    
    init(map: Mapper) throws {
        id = try map.from("id")
        startDate = try map.from("startDate", transformation: DateParser().extractDate)
        stopDate = try map.from("stopDate", transformation: DateParser().extractDate)
        status = try map.from("status") { object in
            guard let string = object as? String, let status = Status(rawValue: string) else {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
            }
            return status
        }
    }
}
