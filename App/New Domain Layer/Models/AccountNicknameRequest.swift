//
//  AccountNicknameRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct AccountNicknameRequest: Encodable {
    let accountNumber: String
    let accountNickname: String
}
