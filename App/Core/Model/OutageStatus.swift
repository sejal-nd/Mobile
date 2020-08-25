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
    let status: String?
    var multipremiseAccount: Bool = false // Set locally for use in unauthenticated logic
    var isAccountInactive: Bool = false
    
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
        status = map.optionalFrom("status")
    }
    
    // MARK: - Outage State
    
    static func getOutageState(_ outageStatus: OutageStatus,
                               reportedResults: ReportedOutageResult? = nil,
                               hasJustReported: Bool = false) -> OutageState {
        
        if AccountsStore.shared.accounts != nil && !AccountsStore.shared.accounts.isEmpty {
            let currentAccount = AccountsStore.shared.currentAccount

            if outageStatus.isAccountInactive {
                return .inactive
            } else if currentAccount.isFinaled || currentAccount.serviceType == nil {
                return .unavailable
            } else if hasJustReported {
                return .reported
            } else if outageStatus.flagFinaled || outageStatus.flagNonService {
                return .unavailable
            } else if outageStatus.flagNoPay {
                return .nonPayment
            }
        }
        
        if hasJustReported {
            return .reported
        }
        
        return .powerStatus(!outageStatus.activeOutage)
    }
    
}

enum OutageState {
    case powerStatus(Bool)
    case reported
    case unavailable
    case nonPayment
    case inactive
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
