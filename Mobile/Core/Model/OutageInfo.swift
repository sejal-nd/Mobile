//
//  OutageInfo.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

enum OutageIssue : String {
    case AllOut = "allOut"
    case PartOut = "partOut"
    case Flickering = "flickering"
}

enum OutageTrivalent : String {
    case Yes = "Yes"
    case No = "No"
    case Unsure = "Unsure"
}


/// Representation of an outage to be reported
struct OutageInfo {
    
    let account: Account
    let reportedTime: Date
    let issue: OutageIssue
    let phoneNumber: String //[0-9]{10}
    var phoneExtension: String? //ComEd and Peco
    var isUnusual: OutageTrivalent? //ComEd
    var unusualMessage: String? //ComEd
    var isNeighbor: OutageTrivalent? //ComEd
    
    init(account: Account,
         issue: OutageIssue,
         phoneNumber: String,
         phoneExtension: String?=nil,
         isUnusual: OutageTrivalent?=nil,
         unusualMessage: String?=nil,
         isNeighbor: OutageTrivalent?=nil) {
        self.account = account
        self.reportedTime = Date()
        self.issue = issue
        self.phoneNumber = phoneNumber
        self.phoneExtension = phoneExtension != nil ? phoneExtension! : nil
        self.isUnusual = isUnusual != nil ? isUnusual! : nil
        self.unusualMessage = unusualMessage != nil ? unusualMessage! : nil
        self.isNeighbor = isNeighbor != nil ? isNeighbor! : nil
    }
}

struct ReportedOutageResult {
    let reportedTime: Date
    let etr: Date
    
    init(reportedTime: Date, etr: Date) {
        self.reportedTime = reportedTime
        self.etr = etr
    }
}
