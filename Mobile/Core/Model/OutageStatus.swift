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
    var flagNonService: Bool
    let meterPingInfo: MeterPingInfo?
    var etr: Date?
    let locationId: String?
    
    init(map: Mapper) throws {
        flagGasOnly = map.optionalFrom("flagGasOnly") ?? false
        contactHomeNumber = map.optionalFrom("contactHomeNumber")
        outageDescription = map.optionalFrom("outageReported")
        activeOutage = map.optionalFrom("status", transformation: extractOutageStatus) ?? false
        smartMeterStatus = map.optionalFrom("smartMeterStatus") ?? false
        flagFinaled = map.optionalFrom("flagFinaled") ?? false
        flagNoPay = map.optionalFrom("flagNoPay") ?? false
        flagNonService = map.optionalFrom("flagNonService") ?? false
        meterPingInfo = map.optionalFrom("meterInfo")
        etr = map.optionalFrom("ETR", transformation: extractDate)
        locationId = map.optionalFrom("locationId")
    }
    
}

struct MeterPingInfo: Mappable {
    let preCheckSuccess: Bool
    let pingResult: Bool
    let voltageResult: Bool
    let voltageReads: String?
    
    init(map: Mapper) throws {
        preCheckSuccess = map.optionalFrom("preCheckSuccess") ?? false
        pingResult = map.optionalFrom("pingResult") ?? false
        voltageResult = map.optionalFrom("voltageResult") ?? false
        voltageReads = map.optionalFrom("voltageReads")
    }
}
