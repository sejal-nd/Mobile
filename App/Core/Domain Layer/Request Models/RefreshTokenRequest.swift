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
        self.client_id = ""
        self.resource = ""
    }
    
    public init(client_id: String,
                refreshToken: String) {
        self.client_id = client_id
        self.grantType = "refresh_token"
        self.response_type = "id_token"
        self.resource = client_id
        self.refreshToken = refreshToken
        self.clientId = ""
        self.clientSecret = ""
    }
    
    var clientId: String
    var clientSecret: String
    var grantType = "refresh_token"
    let refreshToken: String
    var response_type = "id_token"
    var client_id : String
    var resource :  String
    
    /*
     old coding keys
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
    }
    */
    
    enum CodingKeys: String, CodingKey {
        case client_id = "client_id"
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case response_type = "response_type"
        case resource = "resource"
    }
}
