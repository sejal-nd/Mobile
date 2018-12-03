//
//  BillForecast.swift
//  Mobile
//
//  Created by Marc Shilling on 10/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct BillForecastResult {
    let electric: BillForecast?
    let gas: BillForecast?

    init(dictionaries: [[String: Any]]) throws {
        let billForecasts = dictionaries.compactMap { BillForecast.from($0 as NSDictionary) }
        
        electric = billForecasts.first(where: {
            $0.errorMessage == nil && $0.meterType == "ELEC"
        })
        
        gas = billForecasts.first(where: {
            $0.errorMessage == nil && $0.meterType != "ELEC"
        })
    }
}


struct BillForecast: Mappable {
    let errorMessage: String?
    
    // These all need to be optional because to account for the state where errorMessage is passed
    let billingStartDate: Date?
    let billingEndDate: Date?
    let calculationDate: Date?
    let toDateUsage: Double?
    let toDateCost: Double?
    let projectedUsage: Double?
    let projectedCost: Double?
    let baselineUsage: Double?
    let baselineCost: Double?
    let currencySymbol: String?
    
    private let utilityAccount: NSDictionary
    let meterType: String // "ELEC" or "GAS"
    var meterUnit: String
    
    init(map: Mapper) throws {
        errorMessage = map.optionalFrom("errorMessage")
        
        billingStartDate = map.optionalFrom("billingStartDate", transformation: DateParser().extractDate)
        billingEndDate = map.optionalFrom("billingEndDate", transformation: DateParser().extractDate)
        calculationDate = map.optionalFrom("calculationDate", transformation: DateParser().extractDate)
        toDateUsage = map.optionalFrom("toDateUsage")
        toDateCost = map.optionalFrom("toDateCost")
        projectedUsage = map.optionalFrom("projectedUsage")
        projectedCost = map.optionalFrom("projectedCost")
        baselineUsage = map.optionalFrom("baselineUsage")
        baselineCost = map.optionalFrom("baselineCost")
        currencySymbol = map.optionalFrom("currencySymbol")
        
        try utilityAccount = map.from("utilityAccountDTO")
        meterType = utilityAccount.object(forKey: "meterType") as! String
        
        meterUnit = ""
        if let unit = utilityAccount.object(forKey: "meterUnit") as? String {
            meterUnit = unit
        }
        if meterUnit == "KWH" {
            meterUnit = "kWh"
        } else if meterUnit == "THERM" {
            meterUnit = "therms"
        }
    }
}


