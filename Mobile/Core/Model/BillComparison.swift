//
//  BillComparison.swift
//  Mobile
//
//  Created by Marc Shilling on 10/9/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct BillComparison: Mappable {
    let meterUnit: String?
    let currencySymbol: String?
    let temperatureUnit: String?
    
    init(map: Mapper) throws {
        meterUnit = map.optionalFrom("meterUnit")
        currencySymbol = map.optionalFrom("currencySymbol")
        temperatureUnit = map.optionalFrom("temperatureUnit")
    }
}
