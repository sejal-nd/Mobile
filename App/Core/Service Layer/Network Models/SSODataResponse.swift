//
//  SSODataResponse.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct SSODataResponse: Decodable {
    public var ssoPostURL: String
    public var relayState: String
    public var relayStatePESC: String
    public var nonResHost: String?
    public var nonResJSPath: String?
    public var samlResponse: String
    
    public var username: String?
}
