//
//  B2CTokenRequest.swift
//  Mobile
//
//  Created by Vishnu Nair on 20/07/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct B2CTokenRequest: Encodable {
    public init(scope: String? = nil,
                nonce: String = "",
                grantType: String = "password",
                responseType: String = "token id_token",
                username: String = "",
                password: String = "",
                refreshToken: String = "") {
        if let scope = scope {
            self.scope = scope
        }
        self.nonce = nonce
        self.grantType = grantType
        self.responseType = responseType
        self.username = username
        self.password = password
        self.refreshToken = refreshToken
    }
    
    var clientID = Configuration.shared.b2cClientID
    var clientSecret = Configuration.shared.clientSecret
    var scope = Configuration.shared.b2cScope
    var grantType = ""
    var responseType = ""
    var username = ""
    var password = ""
    var refreshToken = ""
    var resource = ""
    var nonce = ""
    
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case scope
        case nonce
        case grantType = "grant_type"
        case responseType = "response_type"
        case username
        case password
        case refreshToken = "refresh_token"
        case resource = "resource"
    }
}
