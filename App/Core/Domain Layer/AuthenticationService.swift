//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

public enum AuthenticationService {
    
    private static let tokenKeychainKey = "jwtToken"
    private static let tokenExpirationDateKeychainKey = "jwtTokenExpirationDate"
    private static let refreshTokenKeychainKey = "jwtRefreshToken"
    private static let refreshTokenExpirationDateKeychainKey = "jwtRefreshTokenExpirationDate"
    private static let refreshTokenIssuedDateKeychainKey = "jwtRefreshTokenIssuedDate"
    
    #if os(iOS)
    private static let tokenKeychain = A0SimpleKeychain()
    #elseif os(watchOS)
    private static let tokenKeychain = KeychainManager.shared
    #endif
    
    static func login(username: String,
                      password: String,
                      completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        if Environment.shared.environmentName != .aut {
            performLogin(username: username,
                         password: password,
                         completion: completion)
        } else {
            performLoginMock(username: username,
                             completion: completion)
        }
    }
    
    static func validateLogin(username: String,
                              password: String,
                              completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        let tokenRequest = TokenRequest(clientId: Environment.shared.clientID,
                                        clientSecret: Environment.shared.clientSecret,
                                        username: "\(Environment.shared.opco.rawValue)\\\(username)",
                                        password: password)
        NetworkingLayer.request(router: .fetchToken(request: tokenRequest)) { (result: Result<VoidDecodable, NetworkingError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func changePassword(request: ChangePasswordRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .passwordChange(request: request), completion: completion)
    }
    
    static func isLoggedIn() -> Bool {
        return !UserSession.token.isEmpty
    }
    
    static func logout(resetNavigation: Bool = true, sendToLogin: Bool = true) {
        NetworkingLayer.cancelAllTasks()

        UserSession.deleteSession()
        
        // We may not even use accounts store anymore.
        AccountsStore.shared.accounts = nil
        AccountsStore.shared.currentIndex = nil
        AccountsStore.shared.customerIdentifier = nil
        StormModeStatus.shared.isOn = false
        
        RxNotifications.shared.configureQuickActions.onNext(false)
        
        #if os(iOS)
        if resetNavigation {
            (UIApplication.shared.delegate as? AppDelegate)?.resetNavigation(sendToLogin: sendToLogin)
        }
        #endif
    }
}

// MARK: Private methods
    
extension AuthenticationService {
    private static func performLogin(username: String,
                                     password: String,
                                     completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        let tokenRequest = TokenRequest(clientId: Environment.shared.clientID,
                                        clientSecret: Environment.shared.clientSecret,
                                        username: "\(Environment.shared.opco.urlString)\\\(username)",
                                        password: password)
        NetworkingLayer.request(router: .fetchToken(request: tokenRequest)) { (result: Result<TokenResponse, NetworkingError>) in
            switch result {
            case .success(let tokenResponse):
                
                // Handle Temp Password
                if tokenResponse.profileStatus?.tempPassword ?? false {
                    completion(.success(true))
                    return
                }
                do {
                    try UserSession.createSession(tokenResponse: tokenResponse)
                } catch {
                    completion(.failure(.invalidToken))
                }
                
                AccountService.fetchAccounts { (result: Result<[Account], NetworkingError>) in
                    switch result {
                    case .success(let accounts):
                        guard let accNumber = accounts.first?.accountNumber else {
                            completion(.failure(.invalidResponse))
                            return
                        }
                        AccountService.fetchAccountDetails(accountNumber: accNumber) { (result: Result<AccountDetail, NetworkingError>) in
                            switch result {
                            case .success(let accountDetail):
                                UserDefaults.standard.set(accountDetail.customerNumber, forKey: UserDefaultKeys.customerIdentifier)
                                AccountsStore.shared.customerIdentifier = accountDetail.customerNumber
                                completion(.success((false)))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private static func performLoginMock(username: String,
                                         completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        // Set mock user
        do {
            try UserSession.createSession(mockUsername: username)
        } catch {
            completion(.failure(.invalidToken))
        }

        AccountService.fetchAccounts { (result: Result<[Account], NetworkingError>) in
            switch result {
            case .success:
                completion(.success((false)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}



