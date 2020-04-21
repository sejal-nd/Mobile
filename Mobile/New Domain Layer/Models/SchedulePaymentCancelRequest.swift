//
//  SchedulePaymentCancelRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct SchedulePaymentCancelRequest: Encodable {
    let paymentAmount: String
    
    enum CodingKeys: String, CodingKey {
        case paymentAmount = "payment_amount"
    }
}
