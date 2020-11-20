//
//  BillForecastResult.swift
//  Mobile
//
//  Created by Cody Dillon on 5/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct BillForecastResult: Decodable {
    var electric: BillForecast? = nil
    var gas: BillForecast? = nil
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        while let forecast = try container.decodeIfPresent(BillForecast.self) {
            if forecast.meterType == "GAS" {
                self.gas = forecast
            } else if forecast.meterType == "ELEC" {
                self.electric = forecast
            }
        }
    }
}
