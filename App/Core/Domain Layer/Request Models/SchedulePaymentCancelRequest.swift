//
//  SchedulePaymentCancelRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct SchedulePaymentCancelRequest: Encodable {
    let paymentAmount: String
    
    init(paymentAmount: Double) {
        self.paymentAmount = String(format: "%.02f", paymentAmount)
    }
    
    enum CodingKeys: String, CodingKey {
        case paymentAmount = "payment_amount"
    }
}
