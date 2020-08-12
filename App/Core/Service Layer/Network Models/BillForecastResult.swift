//
//  BillForecastResult.swift
//  Mobile
//
//  Created by Cody Dillon on 5/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct BillForecastResult: Decodable {
    let electric: BillForecast?
    let gas: BillForecast?
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.electric = try container.decodeIfPresent(BillForecast.self)
        self.gas = try container.decodeIfPresent(BillForecast.self)
    }
}
