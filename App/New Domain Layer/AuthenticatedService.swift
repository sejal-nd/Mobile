//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// NOTE: The location of these static methods are subject to change

struct AuthenticatedService {
    
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
    
    static func fetchAccounts(completion: @escaping (Result<[NewAccount], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .accounts) { (result: Result<[NewAccount], NetworkingError>) in
            switch result {
            case .success(let accounts):
                let sortedAccounts = accounts
                    .filter { !$0.isPasswordProtected } // Filter out password protected accounts
                    .sorted { ($0.isDefault && !$1.isDefault) || (!$0.isFinaled && $1.isFinaled) }
                
//                AccountsStore.shared.accounts = sortedAccounts
                AccountsStore.shared.currentIndex = 0
            case .failure(let error):
                break
            }
        }
    }

    static func fetchAccountDetails(accountNumber: String,
                                    payments: Bool = true,
                                    programs: Bool = true,
                                    budgetBilling: Bool = true,
                                    completion: @escaping (Result<NewAccountDetails, NetworkingError>) -> ()) {
        
        var queryItems = [(String, String)]()
        if !payments {
            queryItems.append(("payments", "false"))
        }
        if !programs {
            queryItems.append(("programs", "false"))
        }
        if !budgetBilling {
            queryItems.append(("budgetBilling", "false"))
        }
        
        let queryStringSubSequence = queryItems
            .map { $0.0 + "=" + $0.1 }
            .reduce("?") { $0 + $1 + "&" }
            .dropLast() // drop the last "&"
        let queryString = String(queryStringSubSequence)
        
        
        NetworkingLayer.request(router: .accountDetails(accountNumber: accountNumber, queryString: queryString)) { (result: Result<NewAccountDetails, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data))
//                NetworkTest.shared.wallet()
                
//                NetworkTest.shared.payment(accountNumber: data.accountNumber)
                
                
                
//                AuthenticatedService.fetchAlertBanner(bannerOnly: true, stormOnly: false) { (result: Result<NewSharePointAlert, NetworkingError>) in
//                    switch result {
//                    case .success(let data):
//                        completion(.success(data.alerts))
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    // todo move from this service
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
                
                self.fetchAccounts { (result: Result<[NewAccount], NetworkingError>) in
                    switch result {
                    case .success(let accounts):
                        guard let accNumber = accounts.first?.accountNumber else { return }
                        AuthenticatedService.fetchAccountDetails(accountNumber: accNumber) { (result: Result<NewAccountDetails, NetworkingError>) in
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
        
        self.fetchAccounts { (result: Result<[NewAccount], NetworkingError>) in
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
