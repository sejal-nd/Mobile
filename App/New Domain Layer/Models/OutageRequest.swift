//
//  OutageRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

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

/// Representation of an outage to be reported
public struct OutageRequest: Encodable {
    
    let accountNumber: String
    var locationId: String?
    var reportedTime: Date = .now
    let issue: OutageIssue
    let phoneNumber: String //[0-9]{10}
    var phoneExtension: String? //ComEd and Peco
    var isUnusual: OutageTrivalent? //ComEd
    var unusualMessage: String? //ComEd
    var isNeighbor: OutageTrivalent? //ComEd
    var comment: String?
    
}
