//
//  AccountLookupRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountLookupRequest: Encodable {
    let phone: String
    let identifier: String
}
