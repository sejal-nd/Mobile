//
//  AccountLookupRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct AccountLookupRequest: Encodable {
    var phone: String
    var identifier: String
}
