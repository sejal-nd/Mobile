//
//  ChangePasswordRequest.swift
//  Mobile
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct ChangePasswordRequest: Encodable {
    var username: String
    var currentPassword: String
    var newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case currentPassword = "old_password"
        case newPassword = "new_password"
    }
}
