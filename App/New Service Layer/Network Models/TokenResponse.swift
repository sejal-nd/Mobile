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
    public var profileStatus: ProfileStatus?
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.token = try container.decodeIfPresent(String.self,
                                                   forKey: .token)
        self.expiresIn = try container.decodeIfPresent(String.self,
                                                       forKey: .expiresIn)
        self.refreshToken = try container.decodeIfPresent(String.self,
                                                          forKey: .refreshToken)
        self.refreshTokenExpiresIn = try container.decodeIfPresent(String.self,
                                                                   forKey: .refreshTokenExpiresIn)
        self.refreshTokenIssuedAt = try container.decodeIfPresent(String.self,
                                                                  forKey: .refreshTokenIssuedAt)
        // Profile Status
        if let token = token, let base64Data = decode(token: token) {
            let statuses = try? JSONDecoder().decode(StatusContainer.self, from: base64Data)
            
            let hasTempPassword = statuses?.status.contains(where: { $0.name == "tempPassword" }) ?? false
            let hasTempPasswordExpired = statuses?.status.contains(where: { $0.tempPasswordFailReason != nil }) ?? false
            let isPrimaryAccount = statuses?.status.contains(where: { $0.name == "primary" }) ?? false
            let isInactive = statuses?.status.contains(where: { $0.name == "inactive" }) ?? false
            let isLockedPassword = statuses?.status.contains(where: { $0.name == "isLockedPassword" }) ?? false
            
            profileStatus = ProfileStatus(inactive: isInactive,
                                          primary: isPrimaryAccount,
                                          passwordLocked: isLockedPassword,
                                          tempPassword: hasTempPassword,
                                          expiredTempPassword: hasTempPasswordExpired)
        }
    }
    
    // MARK: JWT Data
    
    struct StatusContainer: Decodable {
        var status = [TokenProfileStatus]()
        
        struct TokenProfileStatus: Decodable {
            let name: String?
            let tempPasswordFailReason: String?
            
            enum CodingKeys: String, CodingKey {
                case name
                case tempPasswordFailReason = "reason"
            }
        }
    }
}

// MARK: Parse JWT

extension TokenResponse {
    private func decode(token: String) -> Data? {
        let segments = token.components(separatedBy: ".")
        guard segments.indices.contains(1) else { return nil }
        let bodySegment = segments[1]
        return base64UrlDecode(bodySegment)
    }
    
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
}


// todo need to parse token to determine isTempPassword

//        hasTempPassword = profileStatus?.statuses.contains(where: { $0.name == "tempPassword" }) ?? false

// THIS DOES NOT WORK
