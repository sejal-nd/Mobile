//
//  B2CoPowerJWTRequest.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 8/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct B2CoPowerJWTRequest: Encodable {
    let clientID: String
    let refreshToken: String
    let nonce: String
}
