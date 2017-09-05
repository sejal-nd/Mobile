//
//  OutageInfo.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

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

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return dateFormatter.date(from: dateString)
}


/// Representation of an outage to be reported
struct OutageInfo {
    
    let account: Account
    var locationId: String?
    let reportedTime: Date
    let issue: OutageIssue
    let phoneNumber: String //[0-9]{10}
    var phoneExtension: String? //ComEd and Peco
    var isUnusual: OutageTrivalent? //ComEd
    var unusualMessage: String? //ComEd
    var isNeighbor: OutageTrivalent? //ComEd
    
    init(account: Account,
         locationId: String?=nil,
         issue: OutageIssue,
         phoneNumber: String,
         phoneExtension: String?=nil,
         isUnusual: OutageTrivalent?=nil,
         unusualMessage: String?=nil,
         isNeighbor: OutageTrivalent?=nil) {
        self.account = account
        self.locationId = locationId
        self.reportedTime = Date()
        self.issue = issue
        self.phoneNumber = phoneNumber
        self.phoneExtension = phoneExtension
        self.isUnusual = isUnusual
        self.unusualMessage = unusualMessage
        self.isNeighbor = isNeighbor
    }
}

struct ReportedOutageResult: Mappable {
    let reportedTime = Date()
    let etr: Date?
    
    init(map: Mapper) throws {
        etr = map.optionalFrom("etr", transformation: extractDate)
    }
}
