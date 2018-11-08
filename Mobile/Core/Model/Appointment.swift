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
        case scheduled = "accepted"
        case enRoute = "enroute"
        case inProgress = "onsite"
        case complete = "cleared"
        case canceled = "canceled"
    }
    
    let id: String
    let startDate: Date
    let stopDate: Date
    let status: Status
    let caseNumber: String
    
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
        
        caseNumber = id
        //caseNumber = try map.from("caseNumber")
    }
    
    init(id: String, startDate: Date, stopDate: Date, status: Status, caseNumber: String) {
        
        assert(Environment.shared.environmentName == .aut, "init only available for tests")
        
        var map = [String: Any]()
        map["id"] = id
        //TODO: Update these formatters when we get services
        map["startDate"] = DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: startDate)
        map["stopDate"] = DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: stopDate)
        map["status"] = status.rawValue
        map["caseNumber"] = caseNumber
        
        self = Appointment.from(map as NSDictionary)!
    }
}
