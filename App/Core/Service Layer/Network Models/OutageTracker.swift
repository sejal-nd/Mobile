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
                default:
                    return ""
            }
        }
    }
}

struct StatusTitleString {
    // todo - add copy for errors
    static let reported = NSLocalizedString("BGE has received a report of an outage at your address.", comment: "")
    static let assigned = NSLocalizedString("A BGE restoration crew is assigned to your outage.", comment: "")
    static let enRoute = NSLocalizedString("A BGE restoration crew is en route to your outage.", comment: "")
    static let onSite = NSLocalizedString("A BGE restoration crew is at the scene of your outage and working hard to resolve the issue.", comment: "")
    static let restored = NSLocalizedString("Your power has been restored!", comment: "")
}

struct StatusDetailString {
    // todo - guessing here...there are more
    
    static let crewLeftSite = NSLocalizedString("The outage affecting your addresss requires additional repair work to be completed at another location before we can begin work in your area. We appreciate your patience durig this difficult restoration process.", comment: "")
    static let crewDiverted = NSLocalizedString("This can occur during severe emergencies or potentially hazardous situations. A new BGE crew will be dispatched as soon as possible to retore your service.", comment: "")
    static let CrewExtDamage = NSLocalizedString("We have multiple crews on site working hard to restore your power. Thank you for your patience.", comment: "")
}
