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
    let etr: String?
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
        case isOutageValid
        case isMultipleOutage
        case outageID
        case switchPlanID
        case accountID
        case trackerStatus
        case isSafetyHazard
        case isPartialRestoration
        case lastUpdated
        case etr
        case etrType
        case etrOverrideOn
        case stormMode
        case meterStatus
        case cause
        case customersOutOnOutage
        case eventSet
        case isCrewLeftSite
        case isCrewDiverted
        case isCrewExtDamage
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
        
        var statusTitleString: String {
            switch self {
                case .reported:
                    return StatusTitleString.reported
                case .assigned:
                    return StatusTitleString.assigned
                case .enRoute:
                    return StatusTitleString.enRoute
                case .onSite:
                    return StatusTitleString.onSite
                case .restored:
                    return StatusTitleString.restored
                case .none:
                    return StatusTitleString.none
            }
        }
    }
}

struct StatusTitleString {
    static let reported = NSLocalizedString("BGE has received a report of an outage at your address.", comment: "")
    static let assigned = NSLocalizedString("A BGE restoration crew is assigned to your outage.", comment: "")
    static let enRoute = NSLocalizedString("A BGE restoration crew is en route to your outage.", comment: "")
    static let enRouteRerouted = NSLocalizedString("The BGE crew en route to your outage was required to reroute to a new location.", comment: "")
    static let onSite = NSLocalizedString("A BGE restoration crew is at the scene of your outage and working hard to resolve the issue.", comment: "")
    static let onSiteExtDamage = NSLocalizedString("There is extensive equipment damage in your area.", comment: "")
    static let onSiteTempStop = NSLocalizedString("The BGE crew working on your outage needed to temporarily stop their work.", comment: "")
    static let restored = NSLocalizedString("Your power has been restored!", comment: "")
    static let restoredNonDef = NSLocalizedString("Restoration Notification", comment: "")
    static let none = NSLocalizedString("Outage Tracker is Unavailable", comment: "")
}
