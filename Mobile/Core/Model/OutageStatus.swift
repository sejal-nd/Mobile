//
//  OutageStatus.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return dateFormatter.date(from: dateString)
}

private func extractOutageStatus(object: Any?) throws -> Bool {
    guard let status = object as? String else {
        throw MapperError.convertibleError(value: object, type: String.self)
    }
    
    if status == "ACTIVE" {
        return true
    } else {
        return false
    }
}

struct OutageStatus: Mappable {
    let flagGasOnly: Bool
    let contactHomeNumber: String
    let outageDescription: String
    let activeOutage: Bool // "ACTIVE", "NOT ACTIVE"
    let smartMeterStatus: Bool
    var flagFinaled: Bool
    var flagNoPay: Bool
    let meterPingInfo: MeterPingInfo?
    var etr: Date?
    var reportedOutageInfo: OutageInfo?
    
    init(map: Mapper) throws {
        try flagGasOnly = map.from("flagGasOnly")
        try contactHomeNumber = map.from("contactHomeNumber")
        try outageDescription = map.from("outageReported")
        try activeOutage = map.from("status", transformation: extractOutageStatus)
        try smartMeterStatus = map.from("smartMeterStatus")
        do {
            try flagFinaled = map.from("flagFinaled")
        } catch {
            flagFinaled = false
        }
        do {
            try flagNoPay = map.from("flagNoPay")
        } catch {
            flagNoPay = false
        }
        
        meterPingInfo = map.optionalFrom("meterInfo")
        
        do {
            try etr = map.from("ETR", transformation: extractDate)
        } catch {
            etr = nil
        }
        
        reportedOutageInfo = nil
    }
    
}

struct MeterPingInfo: Mappable {
    let preCheckSuccess: Bool
    let pingResult: Bool
    let voltageResult: Bool
    let voltageReads: String
    
    init(map: Mapper) throws {
        try preCheckSuccess = map.from("preCheckSuccess")
        try pingResult = map.from("pingResult")
        try voltageResult = map.from("voltageResult")
        try voltageReads = map.from("voltageReads")
    }
}
