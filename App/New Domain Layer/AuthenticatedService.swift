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
        let tokenRequest = TokenRequest(clientId: Environment.shared.mcsConfig.clientID,
                                        clientSecret: Environment.shared.mcsConfig.clientSecret,
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
    
    // todo may need to be fixed... not confident in implementation
    static func isLoggedIn() -> Bool {
        return !UserSession.token.isEmpty
    }
    
    // todo need to verify cancelAllTasks for network actually works becuase we changed the network configuration
    static func logout() {
        NetworkingLayer.cancelAllTasks()
        
        UserSession.deleteSession()
        
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
                                     completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        let tokenRequest = TokenRequest(clientId: Environment.shared.mcsConfig.clientID,
                                        clientSecret: Environment.shared.mcsConfig.clientSecret,
                                        username: "\(Environment.shared.opco.rawValue)\\\(username)",
                                        password: password)
        print("TOKEN REQUEST EXAMPLE: \(tokenRequest)")
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
                print("FAILURE@@@")
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



