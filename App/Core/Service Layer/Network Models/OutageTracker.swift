//
//  OutageTracker.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/1/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct OutageTracker: Codable {
    let isOutageValid: Bool
    let isMultipleOutage: Bool?
    let outageID: String?
    let switchPlanID: String?
    let accountID: String?
    let trackerStatus: String?
    let isSafetyHazard: Bool?
    let isPartialRestoration: Bool?
    let lastUpdated: String?
    let etrType: String?
    let etrOverrideOn: String?
    let stormMode: String?
    let meterStatus: String?
    let cause: String?
    let customersOutOnOutage: String?
    let eventSet: [EventSet]?
    let isCrewLeftSite: Bool?
    let isCrewDiverted: Bool?
    let isCrewExtDamage: Bool?

    enum CodingKeys: String, CodingKey {
        case isOutageValid, isMultipleOutage, outageID, switchPlanID, accountID, trackerStatus, isSafetyHazard, isPartialRestoration, lastUpdated, etrType, etrOverrideOn, stormMode, meterStatus, cause, customersOutOnOutage, eventSet, isCrewLeftSite, isCrewDiverted, isCrewExtDamage
    }
}

// MARK: - EventSet
struct EventSet: Codable {
    let status: String?
    let eventSetDescription: String?
    let dateTime: String?

    enum CodingKeys: String, CodingKey {
        case status
        case eventSetDescription = "description"
        case dateTime
    }
}


extension OutageTracker {
    enum Status: String {
        case reported = "Outage Reported"
        case assigned = "Crew Assigned"
        case enRoute = "Crew En Route"
        case onSite = "Crew On Site"
        case restored = "Power Restored"
        case none
    }
}
