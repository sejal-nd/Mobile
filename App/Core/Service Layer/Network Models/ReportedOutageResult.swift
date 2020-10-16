//
//  ReportedOutageResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct ReportedOutageResult: Decodable {
    let reportedTime: Date?
    let etr: Date?
    var etrMessage: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case reportedTime
        case etr
        case etrMessage = "etr_message"
    }
}

extension ReportedOutageResult {
    func toDict() -> NSDictionary? {
        var dictionary = [String: Any]()
        guard let reportedTime = reportedTime else {
            return nil
        }
        dictionary["reportedTime"] = DateFormatter.yyyyMMddTHHmmssZZZZZFormatter.string(from: reportedTime)
        dictionary["etr"] = etr?.apiFormatString
        return dictionary as NSDictionary
    }
    
    static func map(from dict: NSDictionary) -> ReportedOutageResult? {
        guard let timeString = dict["reportedTime"] as? String, let etrString = dict["etr"] as? String else {
            return nil
        }
        
        let reportedTime = DateFormatter.yyyyMMddTHHmmssZZZZZFormatter.date(from: timeString)
        let etr = etrString.apiFormatDate
        
        return ReportedOutageResult(reportedTime: reportedTime, etr: etr)
    }
}
