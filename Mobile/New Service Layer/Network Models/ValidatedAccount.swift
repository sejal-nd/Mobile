//
//  ValidatedAccount.swift
//  Mobile
//
//  Created by Cody Dillon on 5/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct ValidatedAccount: Decodable {
    let type: [String]?
    let eBill: Bool?
}
