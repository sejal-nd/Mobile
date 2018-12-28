//
//  ProfileStatus.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct ProfileStatus {
    let inactive: Bool
    let primary: Bool
    let passwordLocked: Bool
    let tempPassword: Bool
    let expiredTempPassword: Bool
    
    init(inactive: Bool = false, primary: Bool = false, passwordLocked: Bool = false, tempPassword: Bool = false,expiredTempPassword: Bool = false) {
        self.inactive = inactive
        self.primary = primary
        self.passwordLocked = passwordLocked
        self.tempPassword = tempPassword
        self.expiredTempPassword = expiredTempPassword
    }
}
