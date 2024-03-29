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
                nonce: String? = nil,
                grantType: String = "password",
                responseType: String = "token",
                username: String? = nil,
                password: String? = nil,
                code: String? = nil,
                codeVerifier: String? = nil,
                refreshToken: String? = nil,
                redirectURI: String? = nil) {
        if let scope = scope {
            self.scope = scope
        }
        self.nonce = nonce
        self.grantType = grantType
        self.responseType = responseType
        self.username = username
        self.password = password
        self.refreshToken = refreshToken
        self.code = code
        self.codeVerifier = codeVerifier
    }
    
    var clientID = Configuration.shared.b2cClientID
    var clientSecret = Configuration.shared.clientSecret
    var scope = Configuration.shared.b2cScope
    var redirectURI: String?
    var grantType: String?
    var responseType: String?
    var username: String?
    var password: String?
    var refreshToken: String?
    var resource: String?
    var nonce: String?
    var code: String?
    var codeVerifier: String?
    
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
        case redirectURI = "redirect_uri"
        case code
        case codeVerifier = "code_verifier"
    }
}
