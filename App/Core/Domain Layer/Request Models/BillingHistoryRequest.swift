//
//  BillingHistoryRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct BillingHistoryRequest: Encodable {
    let startDate: String
    let endDate: String
    let statementType: String
    var billerId: String?
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
        case statementType = "statement_type"
        case billerId = "biller_id"
    }
}
