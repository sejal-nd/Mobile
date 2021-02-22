//
//  UserSession.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum UserSession {
    private static let keychain = KeychainController.default
    
    static var isTokenExpired: Bool {
        return tokenExpirationDate < Date()
    }
    
    static var isRefreshTokenExpired: Bool {
        return refreshTokenExpirationDate < Date()
    }
    
    static var token: String {
        return keychain.string(forKey: .tokenKeychainKey) ?? ""
    }
    
    static var tokenExpirationDate: Date {
        let tokenExpirationDateString = keychain.string(forKey: .tokenExpirationDateKeychainKey) ?? ""
        return Date(timeIntervalSince1970: (tokenExpirationDateString as NSString).doubleValue)
    }
    
    static var refreshToken: String {
        keychain.string(forKey: .refreshTokenKeychainKey) ?? ""
    }
    
    static var refreshTokenExpirationDate: Date {
        let refreshTokenExpirationDateString = keychain.string(forKey: .refreshTokenExpirationDateKeychainKey) ?? ""
        return Date(timeIntervalSince1970: (refreshTokenExpirationDateString as NSString).doubleValue)
    }
}

// MARK: - Create / Send / Delete User Session

extension UserSession {
    static func createSession(tokenResponse: TokenResponse? = nil, mockUsername: String? = nil) throws {
        guard let tokenResponse = tokenResponse,
              let newToken = tokenResponse.token,
              let newTokenExpirationMiliseconds = tokenResponse.expiresIn,
              let newTokenExpirationMilisecondsDouble = Double(newTokenExpirationMiliseconds),
              let newRefreshToken = tokenResponse.refreshToken,
              let newRefreshTokenExpirationMiliseconds = tokenResponse.refreshTokenExpiresIn,
              let newRefreshTokenExpirationMilisecondsDouble = Double(newRefreshTokenExpirationMiliseconds) else {
            if let mockUsername = mockUsername {
                // Mock
                keychain.set(mockUsername, forKey: .tokenKeychainKey)
                return
            } else {
                throw NetworkingError.invalidToken
            }
        }
        
        let tokenExpirationSeconds = newTokenExpirationMilisecondsDouble / 1000
        let newTokenExpirationDate = Date(timeIntervalSinceNow: tokenExpirationSeconds)
        let refreshTokenExpirationSeconds = newRefreshTokenExpirationMilisecondsDouble / 1000
        let newRefreshTokenExpirationDate = Date(timeIntervalSinceNow: refreshTokenExpirationSeconds)
        
        // Save to keychain
        keychain.set(newToken, forKey: .tokenKeychainKey)
        keychain.set("\(newTokenExpirationDate.timeIntervalSince1970)", forKey: .tokenExpirationDateKeychainKey)
        keychain.set(newRefreshToken, forKey: .refreshTokenKeychainKey)
        keychain.set("\(newRefreshTokenExpirationDate.timeIntervalSince1970)", forKey: .refreshTokenExpirationDateKeychainKey)
        
        // Login on Apple Watch / iPhone
        try? WatchSessionController.shared.updateApplicationContext(applicationContext: [
            WatchSessionController.Key.tokenKeychainKey: newToken,
            WatchSessionController.Key.tokenExpirationDateKeychainKey: "\(newTokenExpirationDate.timeIntervalSince1970)",
            WatchSessionController.Key.refreshTokenKeychainKey: newRefreshToken,
            WatchSessionController.Key.refreshTokenExpirationDateKeychainKey: "\(newRefreshTokenExpirationDate.timeIntervalSince1970)"
        ])
    }
    
    static func sendSessionToDevice() {
        try? WatchSessionController.shared.updateApplicationContext(applicationContext: [
            WatchSessionController.Key.tokenKeychainKey: token,
            WatchSessionController.Key.tokenExpirationDateKeychainKey:"\(tokenExpirationDate.timeIntervalSince1970)",
            WatchSessionController.Key.refreshTokenKeychainKey: refreshToken,
            WatchSessionController.Key.refreshTokenExpirationDateKeychainKey: "\(refreshTokenExpirationDate.timeIntervalSince1970)"
        ])
    }
    
    static func deleteSession() {
        keychain.remove(forKey: .tokenKeychainKey)
        keychain.remove(forKey: .tokenExpirationDateKeychainKey)
        keychain.remove(forKey: .refreshTokenKeychainKey)
        keychain.remove(forKey: .refreshTokenExpirationDateKeychainKey)
        UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameAccountNumber)
    }
}
