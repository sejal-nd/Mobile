//
//  AuthTokenResponse.swift
//  Mobile
//
//  Created by Kenny Roethel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct AuthTokenResponse {
    let token: String
    let profileStatus: ProfileStatus
    
    init(token: String, profileStatus: ProfileStatus) {
        self.token = token
        self.profileStatus = profileStatus
    }
}
