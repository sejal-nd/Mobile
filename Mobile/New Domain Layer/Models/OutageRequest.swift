//
//  OutageRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum OutageIssueNew : String, Encodable {
    case allOut = "allOut"
    case partOut = "partOut"
    case flickering = "flickering"
}

enum OutageTrivalentNew : String, Encodable {
    case yes = "Yes"
    case no = "No"
    case unsure = "Unsure"
}

/// Representation of an outage to be reported
struct OutageRequest: Encodable {
    
    let accountNumber: String
    var locationId: String?
    let reportedTime: Date
    let issue: OutageIssueNew
    let phoneNumber: String //[0-9]{10}
    var phoneExtension: String? //ComEd and Peco
    var isUnusual: OutageTrivalentNew? //ComEd
    var unusualMessage: String? //ComEd
    var isNeighbor: OutageTrivalentNew? //ComEd
    var comment: String?
    
    
}
