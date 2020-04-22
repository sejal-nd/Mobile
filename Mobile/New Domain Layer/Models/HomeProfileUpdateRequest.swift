//
//  HomeProfileUpdateRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct HomeProfileUpdateRequest: Encodable {
let adultCount: Int
let childCount: Int
let heatType: String
let squareFeet: Int
let dwellingType: String
    
    enum CodingKeys: String, CodingKey {
        case adultCount = "adult_count"
        case childCount = "child_count"
        case heatType = "heat_type"
        case squareFeet = "square_feet"
        case dwellingType = "dwelling_type"
    }
}
