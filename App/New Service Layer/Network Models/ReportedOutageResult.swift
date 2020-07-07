//
//  NewReportedOutageResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct ReportedOutageResult: Decodable {
    let reportedTime: Date?
    let etr: Date?
}

extension ReportedOutageResult {
    static func map(from dict: NSDictionary) -> ReportedOutageResult? {
        guard let timeString = dict["reportedTime"] as? String, let etrString = dict["etr"] as? String else {
            return nil
        }
        
        let reportedTime = DateFormatter.yyyyMMddTHHmmssZZZZZFormatter.date(from: timeString)
        let etr = etrString.apiFormatDate
        
        return ReportedOutageResult(reportedTime: reportedTime, etr: etr)
    }
}
