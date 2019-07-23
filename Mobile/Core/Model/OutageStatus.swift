//
//  OutageStatus.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

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
    //let meterPingInfo: MeterPingInfo?
    var etr: Date?
    let locationId: String?
    
    // Unauthenticated fields
    let accountNumber: String?
    let maskedAccountNumber: String?
    let maskedAddress: String?
    let addressNumber: String?
    let unitNumber: String?
    var multipremiseAccount: Bool = false // Set locally for use in unauthenticated logic

    init(map: Mapper) throws {
        flagGasOnly = map.optionalFrom("flagGasOnly") ?? false
        contactHomeNumber = map.optionalFrom("contactHomeNumber")
        outageDescription = map.optionalFrom("outageReported")
        activeOutage = map.optionalFrom("status", transformation: extractOutageStatus) ?? false
        smartMeterStatus = map.optionalFrom("smartMeterStatus") ?? false
        flagFinaled = map.optionalFrom("flagFinaled") ?? false
        flagNoPay = map.optionalFrom("flagNoPay") ?? false
        flagNonService = map.optionalFrom("flagNonService") ?? false
        //meterPingInfo = map.optionalFrom("meterInfo")
        etr = map.optionalFrom("ETR", transformation: DateParser().extractDate)
        locationId = map.optionalFrom("locationId")
        
        accountNumber = map.optionalFrom("accountNumber")
        maskedAccountNumber = map.optionalFrom("maskedAccountNumber")
        maskedAddress = map.optionalFrom("maskedAddress")
        addressNumber = map.optionalFrom("addressNumber")
        unitNumber = map.optionalFrom("apartmentUnitNumber")
    }
    
    
    // MARK: - Outage State
    
    static func getOutageState(_ outageStatus: OutageStatus,
                               reportedResults: ReportedOutageResult? = nil,
                               hasJustReported: Bool = false) -> OutageState {
        
        if hasJustReported && reportedResults != nil {
            return .reported
        } else if outageStatus.flagFinaled || outageStatus.flagNonService {
            return .unavailable
        } else if outageStatus.flagNoPay {
            return .nonPayment
        }
        
        return .powerStatus(!outageStatus.activeOutage)
    }
    
}

enum OutageState {
    case powerStatus(Bool)
    case reported
    case unavailable
    case nonPayment
}

struct MeterPingInfo: Mappable {
    //let preCheckSuccess: Bool
    let pingResult: Bool
    let voltageResult: Bool
    let voltageReads: String?
    
    init(map: Mapper) throws {
        //preCheckSuccess = map.optionalFrom("preCheckSuccess") ?? false
        pingResult = map.optionalFrom("pingResult") ?? false
        voltageResult = map.optionalFrom("voltageResult") ?? false
        voltageReads = map.optionalFrom("voltageReads")
    }
}
