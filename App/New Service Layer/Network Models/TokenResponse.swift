//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

//public struct NewJWTToken: Decodable {
//    public var token: String?
//    
//    var hasTempPassword: Bool = false
//    
//    enum CodingKeys: String, CodingKey {
//        case token = "jwt"
//        case profileStatus
//    }
//    
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.token = try container.decode(String.self,
//                                          forKey: .token)
//        let profileStatus = try container.decodeIfPresent(ProfileStatusNew.self,
//                                                          forKey: .profileStatus)
//        hasTempPassword = profileStatus?.statuses.contains(where: { $0.name == "tempPassword" }) ?? false
//    }
//    
//    // MARK: - ProfileStatus
//    private struct ProfileStatusNew: Codable {
//        let statuses: [StatusNew]
//        
//        enum CodingKeys: String, CodingKey {
//            case statuses = "status"
//        }
//    }
//
//    // MARK: - Status
//    private struct StatusNew: Codable {
//        let value: Bool?
//        let name: String
//        let dateTime: Date?
//        
//        enum CodingKeys: String, CodingKey {
//            case value = "value"
//            case name = "name"
//            case dateTime = "dateTime"
//        }
//    }
//}


public struct TokenResponse: Decodable {
    public var token: String?
    public var expiresIn: String?
    public var refreshToken: String?
    public var refreshTokenExpiresIn: String?
    public var refreshTokenIssuedAt: String?
    
    enum CodingKeys: String, CodingKey {
            case token
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case refreshTokenExpiresIn = "refresh_token_expires_in"
            case refreshTokenIssuedAt = "refresh_token_issued_at"
    }
}
