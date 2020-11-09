//
//  SAMLRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct RefreshTokenRequest: Encodable {
    public init(clientId: String,
                clientSecret: String,
                refreshToken: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.grantType = "refresh_token"
        self.refreshToken = refreshToken
    }
    
    var clientId: String
    var clientSecret: String
    var grantType = "password"
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
    }
}
