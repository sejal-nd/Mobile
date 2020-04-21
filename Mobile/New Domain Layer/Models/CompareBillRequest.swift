//
//  CompareBillRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct CompareBillRequest: Encodable {
    let compareWith: String
    let fuelType: String
    
    enum CodingKeys: String, CodingKey {
        case compareWith = "compare_with"
        case fuelType = "fuel_type"
    }
}
