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
    
    init(active: Bool, primary: Bool, passwordLocked: Bool) {
        self.active = active;
        self.primary = primary
        self.passwordLocked = passwordLocked
    }
}
