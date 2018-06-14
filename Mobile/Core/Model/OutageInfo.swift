//
//  OutageInfo.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

enum OutageIssue : String {
    case allOut = "allOut"
    case partOut = "partOut"
    case flickering = "flickering"
}

enum OutageTrivalent : String {
    case yes = "Yes"
    case no = "No"
    case unsure = "Unsure"
}

private func extractDate(object: Any?) throws -> Date? {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    dateFormatter.timeZone = .opCo
    return dateFormatter.date(from: dateString)
}


/// Representation of an outage to be reported
struct OutageInfo {
    
    let accountNumber: String
    var locationId: String?
    let reportedTime: Date
    let issue: OutageIssue
    let phoneNumber: String //[0-9]{10}
    var phoneExtension: String? //ComEd and Peco
    var isUnusual: OutageTrivalent? //ComEd
    var unusualMessage: String? //ComEd
    var isNeighbor: OutageTrivalent? //ComEd
    var comment: String?
    
    init(accountNumber: String,
         locationId: String?=nil,
         issue: OutageIssue,
         phoneNumber: String,
         phoneExtension: String?=nil,
         isUnusual: OutageTrivalent?=nil,
         unusualMessage: String?=nil,
         isNeighbor: OutageTrivalent?=nil,
         comment: String?=nil) {
        self.accountNumber = accountNumber
        self.locationId = locationId
        self.reportedTime = Date()
        self.issue = issue
        self.phoneNumber = phoneNumber
        self.phoneExtension = phoneExtension
        self.isUnusual = isUnusual
        self.unusualMessage = unusualMessage
        self.isNeighbor = isNeighbor
        self.comment = comment
    }
}

struct ReportedOutageResult: Mappable {
    let reportedTime = Date()
    let etr: Date?
    
    init(map: Mapper) throws {
        etr = map.optionalFrom("etr", transformation: extractDate)
    }
}
