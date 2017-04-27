//
//  ProfileStatus.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct ProfileStatus {
    let active: Bool
    let primary: Bool
    let passwordLocked: Bool
    let tempPassword: Bool
    
    init(active: Bool = false, primary: Bool = false, passwordLocked: Bool = false, tempPassword: Bool = false) {
        self.active = active;
        self.primary = primary
        self.passwordLocked = passwordLocked
        self.tempPassword = tempPassword
    }
}
