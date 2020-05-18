//
//  BudgetBillingUnenrollRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/17/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct BudgetBillingUnenrollRequest: Encodable {
    let reason: String
    let comment: String
}
