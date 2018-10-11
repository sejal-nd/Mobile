//
//  Appointment.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct Appointment: Mappable {
    
    enum Status: String {
        case scheduled, enRoute, inProgress, complete, canceled
    }
    
    let startTime: Date
    let endTime: Date
    let status: Status
    let caseNumber: Int
    
    init(map: Mapper) throws {
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
    
    init(startTime: Date = Date(),
         endTime: Date = Date(),
         status: Status = .scheduled,
         caseNumber: Int = 0) {
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.caseNumber = caseNumber
    }
}
