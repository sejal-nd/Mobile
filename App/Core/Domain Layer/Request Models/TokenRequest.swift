//
//  SAMLRequest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/21/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct TokenRequest: Encodable {
    public init(clientId: String,
                clientSecret: String,
                username: String,
                password: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.grantType = "password"
        self.username = username
        self.password = password
        self.scope = ""
        self.client_id = ""
    }
    
    public init(client_id: String,
                scope: String,
                username: String,
                password: String) {
        self.client_id = client_id
        self.scope = scope
        self.grantType = "password"
        self.response_type = "token id_token"
        self.username = username
        self.password = password
        self.clientId = ""
        self.clientSecret = ""
    }
    
    var clientId: String
    var clientSecret: String
    var grantType = "password"
    var response_type = "token id_token"
    var client_id : String
    var scope : String
    let username: String
    let password: String
    
    /*
     Old coding keys
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case grantType = "grant_type"
        case username
        case password
    }
    */
    
    enum CodingKeys: String, CodingKey {
        case client_id = "client_id"
        case scope = "scope"
        case grantType = "grant_type"
        case response_type = "response_type"
        case username
        case password
    }
}
