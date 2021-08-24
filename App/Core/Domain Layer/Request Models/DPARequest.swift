//
//  DPARequest.swift
//  Mobile
//
//  Created by Adarsh Maurya on 21/07/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct DPARequest: Encodable {
    let customerNumber: String
    let premiseNumber: String
    let paymentAmount: String
    let months: String
}
