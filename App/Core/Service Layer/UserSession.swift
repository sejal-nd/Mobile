//
//  UserSession.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum UserSession {
    #if os(iOS)
    private static let tokenKeychain = A0SimpleKeychain()
    #elseif os(watchOS)
    private static let tokenKeychain = KeychainController.shared
    #endif
    
    static let tokenKeychainKey = "jwtToken"
    static let tokenExpirationDateKeychainKey = "jwtTokenExpirationDate"
    static let refreshTokenKeychainKey = "jwtRefreshToken"
    static let refreshTokenExpirationDateKeychainKey = "jwtRefreshTokenExpirationDate"

    static var isTokenExpired: Bool {
        return tokenExpirationDate < Date()
    }
    
    static var isRefreshTokenExpired: Bool {
        return refreshTokenExpirationDate < Date()
    }
    
    static var token: String {
        var token = ""
        #if os(iOS)
        token = tokenKeychain.string(forKey: tokenKeychainKey) ?? ""
        #elseif os(watchOS)
        token = tokenKeychain[AppConstant.WatchSessionKey.authToken] ?? ""
        #endif
        return token
    }
    
    static var tokenExpirationDate: Date {
        var tokenExpirationDateString = ""
        #if os(iOS)
        tokenExpirationDateString = tokenKeychain.string(forKey: tokenExpirationDateKeychainKey) ?? ""
        #elseif os(watchOS)
        tokenExpirationDateString = tokenKeychain[tokenExpirationDateKeychainKey] ?? ""
        #endif
        return Date(timeIntervalSince1970: (tokenExpirationDateString as NSString).doubleValue)
    }
    
    static var refreshToken: String {
        var refreshToken = ""
        #if os(iOS)
        refreshToken = tokenKeychain.string(forKey: refreshTokenKeychainKey) ?? ""
        #elseif os(watchOS)
        refreshToken = tokenKeychain[refreshTokenKeychainKey] ?? ""
        #endif
        return refreshToken
    }
    
    static var refreshTokenExpirationDate: Date {
        var refreshTokenExpirationDateString = ""
        #if os(iOS)
        refreshTokenExpirationDateString = tokenKeychain.string(forKey: refreshTokenExpirationDateKeychainKey) ?? ""
        #elseif os(watchOS)
        refreshTokenExpirationDateString = tokenKeychain[refreshTokenExpirationDateKeychainKey] ?? ""
        #endif
        return Date(timeIntervalSince1970: (refreshTokenExpirationDateString as NSString).doubleValue)
    }
}

// MARK: - Create / Delete User Session

extension UserSession {
    static func createSession(tokenResponse: TokenResponse? = nil, mockUsername: String? = nil) throws {
        guard let tokenResponse = tokenResponse,
            let token = tokenResponse.token,
            let tokenExpiryTime = tokenResponse.expiresIn,
            let refreshToken = tokenResponse.refreshToken,
            let refreshTokenExpiryTime = tokenResponse.refreshTokenExpiresIn else {
                if let mockUsername = mockUsername {
                    // Mock
                    #if os(iOS)
                    // Save to keychain
                    tokenKeychain.setString(mockUsername, forKey: tokenKeychainKey)
                    #elseif os(watchOS)
                    tokenKeychain[UserSession.tokenKeychainKey] = mockUsername
                    #endif
                    return
                } else {
                    throw NetworkingError.invalidToken
                }
        }
        
        #if os(iOS)
        // Save to keychain
        let tokenExpirationSeconds = (Double(tokenExpiryTime) ?? 0.0) / 1000
        let tokenExpirationDate = Date(timeIntervalSinceNow: tokenExpirationSeconds)
        
        let refreshTokenExpirationSeconds = (Double(refreshTokenExpiryTime) ?? 0.0) / 1000
        let refreshTokenExpirationDate = Date(timeIntervalSinceNow: refreshTokenExpirationSeconds)
        
        tokenKeychain.setString(token, forKey: tokenKeychainKey)
        tokenKeychain.setString("\(tokenExpirationDate.timeIntervalSince1970)", forKey: tokenExpirationDateKeychainKey)
        tokenKeychain.setString(refreshToken, forKey: refreshTokenKeychainKey)
        tokenKeychain.setString("\(refreshTokenExpirationDate.timeIntervalSince1970)", forKey: refreshTokenExpirationDateKeychainKey)
        
        // Login on Apple Watch
        if let token = tokenResponse.token {
            try? WatchSessionController.shared.updateApplicationContext(applicationContext: [tokenKeychainKey : token, refreshTokenKeychainKey: refreshToken, tokenExpirationDateKeychainKey: "\(tokenExpirationDate.timeIntervalSince1970)", refreshTokenExpirationDateKeychainKey: "\(refreshTokenExpirationDate.timeIntervalSince1970)"])
        }
        #elseif os(watchOS)
        tokenKeychain[UserSession.tokenKeychainKey] = token
        tokenKeychain[UserSession.tokenExpirationDateKeychainKey] = "\(tokenExpirationDate.timeIntervalSince1970)"
        tokenKeychain[UserSession.refreshTokenKeychainKey] = refreshToken
        tokenKeychain[UserSession.refreshTokenExpirationDateKeychainKey] = "\(refreshTokenExpirationDate.timeIntervalSince1970)"
        #endif
        // todo investigate how we save this to apple watch
    }
    
    static func deleteSession() {
        #if os(iOS)
        tokenKeychain.deleteEntry(forKey: UserSession.tokenKeychainKey)
        tokenKeychain.deleteEntry(forKey: UserSession.tokenExpirationDateKeychainKey)
        tokenKeychain.deleteEntry(forKey: UserSession.refreshTokenKeychainKey)
        tokenKeychain.deleteEntry(forKey: UserSession.refreshTokenExpirationDateKeychainKey)
        #elseif os(watchOS)
        tokenKeychain[UserSession.tokenKeychainKey] = nil
        tokenKeychain[UserSession.tokenExpirationDateKeychainKey] = nil
        tokenKeychain[UserSession.refreshTokenKeychainKey] = nil
        tokenKeychain[UserSession.refreshTokenExpirationDateKeychainKey] = nil
        #endif
        UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameAccountNumber)
    }
}
