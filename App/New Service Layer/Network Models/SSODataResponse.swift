//
//  SSODataResponse.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/22/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct SSODataResponse: Decodable {
    public var utilityCustomerId: String
    public var ssoPostURL: String
    public var relayState: String
    public var samlResponse: String
    public var username: String?
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case utilityCustomerId = "utilityCustomerId"
        case ssoPostURL = "ssoPostURL"
        case relayState = "relayState"
        case samlResponse = "samlResponse"
        case username
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.utilityCustomerId = try data.decode(String.self,
                                                 forKey: .utilityCustomerId)
        self.ssoPostURL = try data.decode(String.self,
                                          forKey: .ssoPostURL)
        self.relayState = try data.decode(String.self,
                                          forKey: .relayState)
        self.samlResponse = try data.decode(String.self,
                                            forKey: .samlResponse)
        self.username = try data.decodeIfPresent(String.self, forKey: .username)
    }
}
