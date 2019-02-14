//
//  Payments.swift
//  Mobile
//
//  Created by Samuel Francis on 12/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct PaymentItem: Mappable {
    
    enum PaymentStatus: String {
        case scheduled = "scheduled"
        case pending = "pending"
        case processing = "processing"
    }
    
    let amount: Double
    let date: Date?
    let status: PaymentStatus
    
    init(map: Mapper) throws {
        amount = try map.from("paymentAmount")
        
        status = try map.from("status") {
            guard let statusString = $0 as? String else {
                throw MapperError.convertibleError(value: $0, type: PaymentStatus.self)
            }
            
            let statusStr: String
            if statusString.lowercased() == "processed" {
                statusStr = "processing"
            } else {
                statusStr = statusString
            }
            
            guard let status = PaymentStatus(rawValue: statusStr.lowercased()) else {
                throw MapperError.convertibleError(value: statusString, type: PaymentStatus.self)
            }
            return status
        }
        
        date = map.optionalFrom("paymentDate", transformation: DateParser().extractDate)
        
        // Scheduled payments require dates
        guard status != .scheduled || date != nil else {
            throw MapperError.convertibleError(value: "paymentDate", type: PaymentStatus.self)
        }
        
    }
}
