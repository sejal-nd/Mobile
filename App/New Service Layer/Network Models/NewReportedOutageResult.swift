//
//  NewReportedOutageResult.swift
//  Mobile
//
//  Created by Cody Dillon on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct NewReportedOutageResult: Decodable {
    let reportedTime: Date?
    let etr: Date?
}
