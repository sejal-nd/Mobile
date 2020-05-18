//
//  SAMLRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct JWTRequest: Encodable {
    let username: String
    let password: String
}
