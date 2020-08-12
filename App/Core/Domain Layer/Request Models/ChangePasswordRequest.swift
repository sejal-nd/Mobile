//
//  ChangePasswordRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct ChangePasswordRequest: Encodable {
    // username must not be nil for anon call
    var username: String? = nil
    let currentPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case currentPassword = "old_password"
        case newPassword = "new_password"
    }
}
