//
//  PKCEB2CTokenRequest.swift
//  Mobile
//
//  Created by Vishnu Nair on 08/12/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import SwiftUI

public struct PKCEB2CTokenRequest: Encodable {
    public init(scope: String? = nil,
                grantType: String = "authorization_code",
                code: String? = nil) {
        if let scope = scope {
            self.scope = scope
        }
        self.grantType = grantType
        self.code = code
    }
    
    var clientID = Configuration.shared.b2cClientID
    var scope = Configuration.shared.b2cScope
    var redirectURI = Configuration.shared.b2cRedirectURI
    var grantType: String?
    var code: String?
    
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case scope
        case grantType = "grant_type"
        case code
        case redirectURI = "redirect_uri"
    }
}
