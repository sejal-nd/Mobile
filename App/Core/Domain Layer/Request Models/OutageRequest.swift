//
//  OutageRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

/// Representation of an outage to be reported
public struct OutageRequest: Encodable {
    let accountNumber: String
    var locationId: String?
    var reportedTime: Date = .now
    let issue: OutageIssue
    var auid: String?
    let phoneNumber: String //[0-9]{10}
    var phoneExtension: String? //ComEd and Peco
    var isUnusual: OutageTrivalent? //ComEd
    var unusualMessage: String? //ComEd
    var isNeighbor: OutageTrivalent? //ComEd
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case locationId = "location_id"
        case reportedTime
        case issue = "outage_issue"
        case phoneNumber = "phone"
        case phoneExtension = "ext"
        case isUnusual = "unusual"
        case unusualMessage = "unusual_specify"
        case isNeighbor = "neighbor"
        case auid 
    }
}

public enum OutageIssue: String, Encodable {
    case allOut = "allOut"
    case partOut = "partOut"
    case flickering = "flickering"
}

public enum OutageTrivalent: String, Encodable {
    case yes = "Yes"
    case no = "No"
    case unsure = "Unsure"
}

