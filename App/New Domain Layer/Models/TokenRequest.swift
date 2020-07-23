//
//  SAMLRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct TokenRequest: Encodable {
    public init(clientId: String = "WbCpJpfgV64WTTDg",
                clientSecret: String = "zWkH8cTa1KphCB4iElbYSBGkL6Fl66KL",
                grantType: String = "password",
                username: String,
                password: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.grantType = grantType
        self.username = username
        self.password = password
    }
    
    var clientId = ""
    var clientSecret = ""
    var grantType = "password"
    let username: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case grantType = "grant_type"
        case username
        case password
    }
}
