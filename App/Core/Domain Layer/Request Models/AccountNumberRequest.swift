//
//  AccountNumberRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 10/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountNumberRequest: Encodable {
    let accountNumber: String
    let accountNickname: String
}
