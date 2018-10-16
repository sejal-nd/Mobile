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
        case scheduled, enRoute, inProgress, complete, canceled
    }
    
    let jobId: String
    let startTime: Date
    let endTime: Date
    let status: Status
    let caseNumber: String
    
    init(map: Mapper) throws {
        jobId = try map.from("jobId")
        startTime = try map.from("startTime", transformation: DateParser().extractDate)
        endTime = try map.from("endTime", transformation: DateParser().extractDate)
        status = try map.from("status") { object in
            guard let string = object as? String,
                let status = Status(rawValue: string) else {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
            }
            
            return status
        }
        
        caseNumber = try map.from("caseNumber")
    }
    
    init(jobId: String, startTime: Date, endTime: Date, status: Status, caseNumber: String) {
        
        assert(Environment.shared.environmentName == .aut, "init only available for tests")
        
        var map = [String: Any]()
        map["jobId"] = jobId
        //TODO: Update these formatters when we get services
        map["startTime"] = DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: startTime)
        map["endTime"] = DateFormatter.yyyyMMddTHHmmssZFormatter.string(from: endTime)
        map["status"] = status.rawValue
        map["caseNumber"] = caseNumber
        
        self = Appointment.from(map as NSDictionary)!
    }
}
