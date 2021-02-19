//
//  UserSession.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum UserSession {
    
    // Todo: migrate iPhone keychain to use lightweight implementation used on watch (this will allow us to remove all #if os checks), will need to add biometric auth option to watch code.
    #if os(iOS)
    private static let keychain = A0SimpleKeychain()
    #elseif os(watchOS)
    private static let keychain = KeychainController.shared
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
        token = keychain.string(forKey: tokenKeychainKey) ?? ""
        #elseif os(watchOS)
        token = keychain[tokenKeychainKey] ?? ""
        #endif
        return token
    }
    
    static var tokenExpirationDate: Date {
        var tokenExpirationDateString = ""
        #if os(iOS)
        tokenExpirationDateString = keychain.string(forKey: tokenExpirationDateKeychainKey) ?? ""
        #elseif os(watchOS)
        tokenExpirationDateString = keychain[tokenExpirationDateKeychainKey] ?? ""
        #endif
        return Date(timeIntervalSince1970: (tokenExpirationDateString as NSString).doubleValue)
    }
    
    static var refreshToken: String {
        var refreshToken = ""
        #if os(iOS)
        refreshToken = keychain.string(forKey: refreshTokenKeychainKey) ?? ""
        #elseif os(watchOS)
        refreshToken = keychain[refreshTokenKeychainKey] ?? ""
        #endif
        return refreshToken
    }
    
    static var refreshTokenExpirationDate: Date {
        var refreshTokenExpirationDateString = ""
        #if os(iOS)
        refreshTokenExpirationDateString = keychain.string(forKey: refreshTokenExpirationDateKeychainKey) ?? ""
        #elseif os(watchOS)
        refreshTokenExpirationDateString = keychain[refreshTokenExpirationDateKeychainKey] ?? ""
        #endif
        return Date(timeIntervalSince1970: (refreshTokenExpirationDateString as NSString).doubleValue)
    }
}

// MARK: - Create / Send / Delete User Session

extension UserSession {
    static func createSession(tokenResponse: TokenResponse? = nil, mockUsername: String? = nil) throws {
        guard let tokenResponse = tokenResponse,
              let token = tokenResponse.token,
              let tokenExpirationMiliseconds = tokenResponse.expiresIn,
              let tokenExpirationMilisecondsDouble = Double(tokenExpirationMiliseconds),
              let refreshToken = tokenResponse.refreshToken,
              let refreshTokenExpirationMiliseconds = tokenResponse.refreshTokenExpiresIn,
              let refreshTokenExpirationMilisecondsDouble = Double(refreshTokenExpirationMiliseconds) else {
            if let mockUsername = mockUsername {
                // Mock
                #if os(iOS)
                // Save to keychain
                keychain.setString(mockUsername, forKey: tokenKeychainKey)
                #elseif os(watchOS)
                keychain[tokenKeychainKey] = mockUsername
                #endif
                return
            } else {
                throw NetworkingError.invalidToken
            }
        }
        
        let tokenExpirationSeconds = tokenExpirationMilisecondsDouble / 1000
        let tokenExpirationDate = Date(timeIntervalSinceNow: tokenExpirationSeconds)
        let refreshTokenExpirationSeconds = refreshTokenExpirationMilisecondsDouble / 1000
        let refreshTokenExpirationDate = Date(timeIntervalSinceNow: refreshTokenExpirationSeconds)
        
        #if os(iOS)
        // Save to keychain
        keychain.setString(token, forKey: tokenKeychainKey)
        keychain.setString("\(tokenExpirationDate.timeIntervalSince1970)", forKey: tokenExpirationDateKeychainKey)
        keychain.setString(refreshToken, forKey: refreshTokenKeychainKey)
        keychain.setString("\(refreshTokenExpirationDate.timeIntervalSince1970)", forKey: refreshTokenExpirationDateKeychainKey)
        #elseif os(watchOS)
        // Save to keychain
        keychain[tokenKeychainKey] = token
        keychain[tokenExpirationDateKeychainKey] = "\(tokenExpirationDate.timeIntervalSince1970)"
        keychain[refreshTokenKeychainKey] = refreshToken
        keychain[refreshTokenExpirationDateKeychainKey] = "\(refreshTokenExpirationDate.timeIntervalSince1970)"
        #endif
        
        // Login on Apple Watch / iPhone
        try? WatchSessionController.shared.updateApplicationContext(applicationContext: [
            tokenKeychainKey: token,
            tokenExpirationDateKeychainKey: "\(tokenExpirationDate.timeIntervalSince1970)",
            refreshTokenKeychainKey: refreshToken,
            refreshTokenExpirationDateKeychainKey: "\(refreshTokenExpirationDate.timeIntervalSince1970)"
        ])
    }
    
    static func sendSessionToDevice() {
        try? WatchSessionController.shared.updateApplicationContext(applicationContext: [
            tokenKeychainKey: token,
            tokenExpirationDateKeychainKey:"\(tokenExpirationDate.timeIntervalSince1970)",
            refreshTokenKeychainKey: refreshToken,
            refreshTokenExpirationDateKeychainKey: "\(refreshTokenExpirationDate.timeIntervalSince1970)"
        ])
    }
    
    static func deleteSession() {
        #if os(iOS)
        keychain.deleteEntry(forKey: tokenKeychainKey)
        keychain.deleteEntry(forKey: tokenExpirationDateKeychainKey)
        keychain.deleteEntry(forKey: refreshTokenKeychainKey)
        keychain.deleteEntry(forKey: refreshTokenExpirationDateKeychainKey)
        UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameAccountNumber)
        #elseif os(watchOS)
        keychain[tokenKeychainKey] = nil
        keychain[tokenExpirationDateKeychainKey] = nil
        keychain[refreshTokenKeychainKey] = nil
        keychain[refreshTokenExpirationDateKeychainKey] = nil
        #endif
    }
}
