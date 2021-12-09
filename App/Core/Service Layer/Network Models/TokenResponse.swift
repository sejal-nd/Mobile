//
//  NewMinimumVersion.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/9/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct TokenResponse: Decodable {
    public var token: String?
    public var profileStatus: ProfileStatus?
    public var userType: String?
    public var expiresIn: String?
    public var refreshToken: String?
    public var refreshTokenExpiresIn: String?
    public var refreshTokenIssuedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case token
        case access_token = "id_token"
        case expiresIn = "id_token_expires_in"
        case refreshToken = "refresh_token"
        case refreshTokenExpiresIn = "refresh_token_expires_in"
        case refreshTokenIssuedAt = "refresh_token_issued_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if FeatureFlagUtility.shared.bool(forKey: .isAzureAuthentication) {
            // B2C JSON has a key access_token instead of token
            self.token = try container.decodeIfPresent(String.self,
                                                           forKey: .access_token)
        } else {
            self.token = try container.decodeIfPresent(String.self,
                                                           forKey: .token)
        }
        
        do {
            expiresIn = try String(container.decodeIfPresent(Int.self, forKey: .expiresIn) ?? 0)
        } catch DecodingError.typeMismatch {
            expiresIn = try container.decodeIfPresent(String.self, forKey: .expiresIn)
        }
        
        self.refreshToken = try container.decodeIfPresent(String.self,
                                                          forKey: .refreshToken)
        
        if FeatureFlagUtility.shared.bool(forKey: .isAzureAuthentication) {
            do {
                self.refreshTokenExpiresIn = try String(container.decodeIfPresent(Int.self, forKey: .refreshTokenExpiresIn) ?? 0)
            } catch DecodingError.typeMismatch {
                self.refreshTokenExpiresIn = try container.decodeIfPresent(String.self, forKey: .refreshTokenExpiresIn)
            }
        } else {
            self.refreshTokenExpiresIn = try container.decodeIfPresent(String.self,
                                                                       forKey: .refreshTokenExpiresIn)
        }
        
        self.refreshTokenIssuedAt = try container.decodeIfPresent(String.self,
                                                                  forKey: .refreshTokenIssuedAt)
        
        if FeatureFlagUtility.shared.bool(forKey: .isAzureAuthentication) {
            // Map additional data from b2c token if any
            if let token = self.token, let base64Data = decode(token: token) {
                do {
                    let json = try JSONSerialization.jsonObject(with: base64Data, options: .mutableContainers) as? [String:AnyObject]
                    if let json = json, let code = json["type"] as? String {
                        self.userType = code
                    }
                } catch {
                    Log.error("Error with B2C token structure")
                }
            }
        } else {
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
        
        
        if let token = token, let base64Data = decode(token: token) {
            let identity = try? JSONDecoder().decode(IdToken.self, from: base64Data)
            self.refreshTokenIssuedAt = identity?.issuedAt
        }
        
    }
    
    // MARK: JWT Data
    
    struct IdToken: Decodable {
        let name: String?
        let issuedAt: String?
        let expiry: String?
        let issuer: String?
        let user: String?
        let givenName: String?
        let familyName: String?
        let opco: String?
        let identityProvider: String?
        
        enum CodingKeys: String, CodingKey {
            case name
            case issuedAt = "iat"
            case expiry = "exp"
            case issuer = "iss"
            case user = "user"
            case givenName = "given_name"
            case familyName = "family_name"
            case opco = "opco"
            case identityProvider = "idp"
        }
    }
    
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
