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
    let contactHomeNumber: String?
    let outageDescription: String?
    let activeOutage: Bool // "ACTIVE", "NOT ACTIVE"
    let smartMeterStatus: Bool
    var flagFinaled: Bool
    var flagNoPay: Bool
    let meterPingInfo: MeterPingInfo?
    var etr: Date?
    
    init(map: Mapper) throws {
        do {
            try flagGasOnly = map.from("flagGasOnly")
        } catch {
            flagGasOnly = false
        }
        
        contactHomeNumber = map.optionalFrom("contactHomeNumber")
        outageDescription = map.optionalFrom("outageReported")
        
        do {
            try activeOutage = map.from("status", transformation: extractOutageStatus)
        } catch {
            activeOutage = false
        }
        
        do {
            try smartMeterStatus = map.from("smartMeterStatus")
        } catch {
            smartMeterStatus = false
        }
        
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
    }
    
}

struct MeterPingInfo: Mappable {
    let preCheckSuccess: Bool
    let pingResult: Bool
    let voltageResult: Bool
    let voltageReads: String?
    
    init(map: Mapper) throws {
        do {
            try preCheckSuccess = map.from("preCheckSuccess")
        } catch {
            preCheckSuccess = false
        }
        
        do {
            try pingResult = map.from("pingResult")
        } catch {
            pingResult = false
        }
        
        do {
            try voltageResult = map.from("voltageResult")
        } catch {
            voltageResult = false
        }

        voltageReads = map.optionalFrom("voltageReads")
    }
}
