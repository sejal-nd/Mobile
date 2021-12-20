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
                case .none:
                    return StatusTitleString.none
            }
        }
    }
}

struct StatusTitleString {
    // todo - add copy for errors
    static let reported = NSLocalizedString("BGE has received a report of an outage at your address.", comment: "")
    static let assigned = NSLocalizedString("A BGE restoration crew is assigned to your outage.", comment: "")
    static let enRoute = NSLocalizedString("A BGE restoration crew is en route to your outage.", comment: "")
    static let enRouteRerouted = NSLocalizedString("The BGE crew en route to your outage was required to reroute to a new location.", comment: "")
    static let onSite = NSLocalizedString("A BGE restoration crew is at the scene of your outage and working hard to resolve the issue.", comment: "")
    static let onSiteExtDamage = NSLocalizedString("There is extensive equipment damage in your area.", comment: "")
    static let onSiteTempStop = NSLocalizedString("The BGE crew working on your outage needed to temporarily stop their work.", comment: "")
    static let restored = NSLocalizedString("Your power has been restored!", comment: "")
    static let none = NSLocalizedString("Outage Tracker is Unavailable", comment: "")
}

struct StatusDetailString {
    
    static let crewLeftSite = NSLocalizedString("The outage affecting your address requires additional repair work to be completed at another location before we can begin work in your area. We appreciate your patience during this difficult restoration process.", comment: "")
    static let crewDiverted = NSLocalizedString("This can occur during severe emergencies or potentially hazardous situations. A new BGE crew will be dispatched as soon as possible to retore your service.", comment: "")
    static let crewExtDamage = NSLocalizedString("We have multiple crews on site working hard to restore your power. Thank you for your patience.", comment: "")
    static let crewSafetyHazard = NSLocalizedString("", comment: "")
    static let partialRestoration = "BGE was able to restore service to some customers in your area, but due to the location of the damage, you and %@ others are still affected by this outage."
    static let trackerNone = NSLocalizedString("We’re actively trying to fix the problem, please check back soon. If your power is not on, please help us by reporting the outage.", comment: "")
    
    // restored
    static let restoredDefLong = NSLocalizedString("Our systems indicate that the power has been restored to your address. We understand that you have been without power for an extended time. We appreciate your patience during this difficult restoration process.", comment: "")
    static let restoredDefReg = NSLocalizedString("Our systems indicate that the power has been restored to your address.", comment: "")
    static let restoredDefShort = NSLocalizedString("Our systems indicate that the power has been restored to your address. We understand that even brief power outages can be a significant inconvenience, and we appreciate your patience.", comment: "")
    static let restoredNonDefLong = NSLocalizedString("We have received notification from our repair crew that the power at your address has been restored. However, we have not yet received confirmation from your smart meter. We understand that you have been without power for an extended time. We appreciate your patience during this difficult restoration process.", comment: "")
    static let restoredNonDefReg = NSLocalizedString("We have received notification from our repair crew that the power at your address has been restored. However, we have not yet received confirmation from your smart meter.", comment: "")
}
