//
//  MaintenanceStatus.swift
//  Mobile
//
//  Created by Constantin Koehler on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

struct Maintenance: Mappable {
    let allStatus: Bool
    var homeStatus: Bool
    var billStatus: Bool
    var outageStatus: Bool
    let alertStatus: Bool
    var usageStatus: Bool
    let stormModeStatus: Bool
    
    let allMessage: String?
    
    init(map: Mapper) throws {
        // VSTS Task 124538 - Make all Prod Beta builds ignore Maintenance Mode
        if Environment.shared.environmentName == .prodbeta {
            allStatus = false
            homeStatus = false
            billStatus = false
            outageStatus = false
            alertStatus = false
            usageStatus = false
            stormModeStatus = false
            allMessage = nil
            return
        }
        
        allStatus = map.optionalFrom("all") ?? false || map.optionalFrom("ios.all") ?? false
        homeStatus = map.optionalFrom("home") ?? false || map.optionalFrom("ios.home") ?? false
        billStatus = map.optionalFrom("bill") ?? false || map.optionalFrom("ios.bill") ?? false
        outageStatus = map.optionalFrom("outage") ?? false || map.optionalFrom("ios.outage") ?? false
        alertStatus = map.optionalFrom("alerts") ?? false || map.optionalFrom("ios.alerts") ?? false
        usageStatus = map.optionalFrom("usage") ?? false || map.optionalFrom("ios.usage") ?? false
        homeStatus = true
        billStatus = true
        outageStatus = true
        usageStatus = true
        stormModeStatus = map.optionalFrom("storm") ?? false // Real Storm Mode value
        //stormModeStatus = true // Force Storm Mode
        //stormModeStatus = Int.random(in: 1...5) != 1 // 1 in 5 chance to test exiting Storm Mode
        
        let iOSMessage = map.optionalFrom("ios.message") ?? ""
        let globalMessage = map.optionalFrom("message") ?? ""
        if !iOSMessage.isEmpty {
            allMessage = iOSMessage
        } else if !globalMessage.isEmpty {
            allMessage = globalMessage
        } else {
            allMessage = nil
        }
    }
    
}
