//
//  B2CTokenRequest.swift
//  Mobile
//
//  Created by Vishnu Nair on 20/07/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public struct B2CTokenRequest: Encodable {
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
    
    enum CodingKeys: String, CodingKey {
        case client_id = "client_id"
        case scope = "scope"
        case grantType = "grant_type"
        case response_type = "response_type"
        case username
        case password
    }
}
