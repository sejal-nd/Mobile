//
//  KeychainKeys.swift
//  Mobile
//
//  Created by Joseph Erlandson on 2/22/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public extension KeychainController {
    enum Key: String {
        // iPhone biometric login
        case keychainKey = "kExelon_PW"
        // oAuth token
        case tokenKeychainKey = "jwtToken"
        // oAuth token expiration date
        case tokenExpirationDateKeychainKey = "jwtTokenExpirationDate"
        // oAuth refresh token
        case refreshTokenKeychainKey = "jwtRefreshToken"
        // oAuth refresh token expiration date
        case refreshTokenExpirationDateKeychainKey = "jwtRefreshTokenExpirationDate"
    }
}
