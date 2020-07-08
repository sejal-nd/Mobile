//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

// NOTE: The location of these static methods are subject to change

public struct AuthenticatedService {
    
    private static let TOKEN_KEYCHAIN_KEY = "kExelon_Token"
    #if os(iOS)
    private static let tokenKeychain = A0SimpleKeychain()
    #elseif os(watchOS)
    private static let tokenKeychain = KeychainManager.shared
    #endif
    
    static func login(username: String,
                      password: String,
                      shouldSaveToKeychain: Bool,
                      completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        if Environment.shared.environmentName != .aut {
            performLogin(username: username,
                         password: password,
                         shouldSaveToKeychain: shouldSaveToKeychain,
                         completion: completion)
        } else {
            performLoginMock(username: username,
                             completion: completion)
        }
    }
    
    static func logout() {
        NetworkingLayer.cancelAllTasks()
        
        #if os(iOS)
        AuthenticatedService.tokenKeychain.deleteEntry(forKey: AuthenticatedService.TOKEN_KEYCHAIN_KEY)
        #elseif os(watchOS)
        AuthenticatedService.tokenKeychain[AuthenticatedService.TOKEN_KEYCHAIN_KEY] = nil
        #endif
        UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameAccountNumber)
        
        UserSession.shared.token = "" // This might be wrong
        
        
        // We may not even use accounts store anymore.
        AccountsStore.shared.accounts = nil
        AccountsStore.shared.currentIndex = nil
        AccountsStore.shared.customerIdentifier = nil
        StormModeStatus.shared.isOn = false
    }
    
    
    // MARK: todo move from this service
    static func fetchAlertBanner(bannerOnly: Bool, stormOnly: Bool, completion: @escaping (Result<[NewAlert], NetworkingError>) -> ()) {
        var filterString: String

        if bannerOnly {
            filterString = "(Enable eq 1) and (CustomerType eq 'Banner')"
        } else if stormOnly {
            filterString = "(Enable eq 1) and (CustomerType eq 'Storm')"
        } else {
            filterString = "(Enable eq 1) and ((CustomerType eq 'All')"
            ["Banner", "PeakRewards", "Peak Time Savings", "Smart Energy Rewards", "Storm"]
                .forEach {
                    filterString += "or (CustomerType eq '\($0)')"
            }
            filterString += ")"
        }
        
        let queryItem = URLQueryItem(name: "$filter", value: filterString)
        
        NetworkingLayer.request(router: .alertBanner(additionalQueryItem: queryItem)) { (result: Result<NewSharePointAlert, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data.alerts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: Private methods
    
extension AuthenticatedService {
    
    private static func performLogin(username: String,
                                     password: String,
                                     shouldSaveToKeychain: Bool,
                                     completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        guard let username = username.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved),
            let password = password.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) else {
                return
        }
        
        let jwtRequest = JWTRequest(username: username, password: password)
        NetworkingLayer.request(router: .fetchJWTToken(request: jwtRequest)) { (result: Result<NewJWTToken, NetworkingError>) in
            switch result {
            case .success(let data):
                
                // Handle Temp Password
                if data.hasTempPassword {
                    completion(.success(data.hasTempPassword))
                    return
                }
                
                guard let token = data.token else { return }
                
                #if os(iOS)
                if shouldSaveToKeychain {
                    // Save Keep Me Signed In status
                    UserDefaults.standard.set(shouldSaveToKeychain,
                                              forKey: UserDefaultKeys.isKeepMeSignedInChecked)
                    // Save to keychain
                    tokenKeychain.setString(token, forKey: TOKEN_KEYCHAIN_KEY)
                    
                    // Login on Apple Watch
                    if let token = data.token {
                        try? WatchSessionManager.shared.updateApplicationContext(applicationContext: ["authToken" : token])
                    }
                }
                #endif

                UserSession.shared.token = token
                
                NewAccountService.fetchAccounts { (result: Result<[Account], NetworkingError>) in
                    switch result {
                    case .success(let accounts):
                        guard let accNumber = accounts.first?.accountNumber else {
                            completion(.failure(.invalidResponse))
                            return
                        }
                        NewAccountService.fetchAccountDetails(accountNumber: accNumber) { (result: Result<AccountDetail, NetworkingError>) in
                            switch result {
                            case .success:
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
        // SET MOCK USER
        UserSession.shared.token = username
        
        NewAccountService.fetchAccounts { (result: Result<[Account], NetworkingError>) in
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



