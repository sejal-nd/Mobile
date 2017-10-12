//
//  BillForecast.swift
//  Mobile
//
//  Created by Marc Shilling on 10/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func extractDate(object: Any?) throws -> Date {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.date(from: dateString)!
}

private func extractCalculationDate(object: Any?) throws -> Date {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return dateFormatter.date(from: dateString)!
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
    
    init(map: Mapper) throws {
        errorMessage = map.optionalFrom("errorMessage")
        
        billingStartDate = map.optionalFrom("billingStartDate", transformation: extractDate)
        billingEndDate = map.optionalFrom("billingEndDate", transformation: extractDate)
        calculationDate = map.optionalFrom("calculationDate", transformation: extractCalculationDate)
        toDateUsage = map.optionalFrom("toDateUsage")
        toDateCost = map.optionalFrom("toDateCost")
        projectedUsage = map.optionalFrom("projectedUsage")
        projectedCost = map.optionalFrom("projectedCost")
        baselineUsage = map.optionalFrom("baselineUsage")
        baselineCost = map.optionalFrom("baselineCost")
        currencySymbol = map.optionalFrom("currencySymbol")
        
        try utilityAccount = map.from("utilityAccountDTO")
        meterType = utilityAccount.object(forKey: "meterType") as! String
    }
}


