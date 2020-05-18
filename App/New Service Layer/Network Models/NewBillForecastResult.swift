//
//  NewBillForecastResult.swift
//  Mobile
//
//  Created by Cody Dillon on 5/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewBillForecastResult {
    let electric: NewBillForecast?
    let gas: NewBillForecast?
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.electric = try container.decodeIfPresent(NewBillForecast.self)
        self.gas = try container.decodeIfPresent(NewBillForecast.self)
    }
}
