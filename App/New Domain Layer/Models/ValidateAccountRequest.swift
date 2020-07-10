//
//  ValidateAccountRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 5/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ValidateAccountRequest: Encodable {
    let phone: String
    let identifier: String
    let accountNum: String?
}
