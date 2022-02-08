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
    
    static func loginWithCode(code: String,
                              codeVerifier: String,
                              completion: @escaping (Result<TokenResponse, NetworkingError>) -> ()) {
        
        if Configuration.shared.environmentName != .aut {
            performLoginWithCode(code: code, codeVerifier: codeVerifier, completion: completion)
        } else {
            #warning("need to create performLoginWithCodeMock")
//            performLoginMock(username: "pkceuser",
//                             completion: completion)
        }
    }
    
    static func login(username: String,
                      password: String,
                      completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        
        if Configuration.shared.environmentName != .aut {
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
        if FeatureFlagUtility.shared.bool(forKey: .isAzureAuthentication) {
            let tokenRequest = B2CTokenRequest(username: username,
                                               password: password)
            NetworkingLayer.request(router: .getAzureToken(request: tokenRequest)) { (result: Result<VoidDecodable, NetworkingError>) in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            let tokenRequest = TokenRequest(clientId: Configuration.shared.clientID,
                                            clientSecret: Configuration.shared.clientSecret,
                                            username: "\(Configuration.shared.opco.urlString)\\\(username)",
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
        
        AssistanceProgramStore.shared.clearStore()
        
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
    
    private static func fetchLoginTokenWithCode(code: String,
                                                codeVerifier: String,
                                                completion: @escaping (Result<TokenResponse, NetworkingError>) -> ()) {
        let tokenRequest = B2CTokenRequest(grantType: "authorization_code", code: code, codeVerifier: codeVerifier, redirectURI: Configuration.shared.b2cRedirectURI)
        NetworkingLayer.request(router: .getAzureToken(request: tokenRequest)) { (result: Result<TokenResponse, NetworkingError>) in
            switch result {
            case .success(let tokenResponse):
                completion(.success(tokenResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private static func fetchLoginToken(username: String,
                             password: String,
                             completion: @escaping (Result<TokenResponse, NetworkingError>) -> ()) {
        if FeatureFlagUtility.shared.bool(forKey: .isAzureAuthentication) {
            // B2C Authentication
            let tokenRequest = B2CTokenRequest(username: username,
                                               password: password)
            NetworkingLayer.request(router: .getAzureToken(request: tokenRequest)) { (result: Result<TokenResponse, NetworkingError>) in
                switch result {
                case .success(let tokenResponse):
                    completion(.success(tokenResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            // Apigee Authentication
            let tokenRequest = TokenRequest(clientId: Configuration.shared.clientID,
                                            clientSecret: Configuration.shared.clientSecret,
                                            username: "\(Configuration.shared.opco.urlString)\\\(username)",
                                            password: password)
            NetworkingLayer.request(router: .fetchToken(request: tokenRequest)) { (result: Result<TokenResponse, NetworkingError>) in
                switch result {
                case .success(let tokenResponse):
                    completion(.success(tokenResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func performLoginWithCode(code: String,
                                             codeVerifier: String,
                                             completion: @escaping (Result<TokenResponse, NetworkingError>) -> ()) {
        fetchLoginTokenWithCode(code: code, codeVerifier: codeVerifier) { (result: (Result<TokenResponse, NetworkingError>)) in
            switch result {
            case .success(let tokenResponse):
                #if os(iOS)
                FirebaseUtility.logEvent(.loginTokenNetworkComplete)
                #endif

                RxNotifications.shared.mfaJustEnabled.accept(tokenResponse.isMfaJustEnabled)
                RxNotifications.shared.mfaBypass.accept(tokenResponse.isMfaBypass)
                RxNotifications.shared.profileEditAction.accept(tokenResponse.profileEditAction)
                
                // Handle Temp Password
                if tokenResponse.profileStatus?.tempPassword ?? false {
                    completion(.success(tokenResponse))
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
                        #if os(iOS)
                        FirebaseUtility.logEvent(.loginAccountNetworkComplete)
                        #endif
                        
                        guard let accNumber = accounts.first?.accountNumber else {
                            completion(.failure(.invalidResponse))
                            return
                        }
                        AccountService.fetchAccountDetails(accountNumber: accNumber,
                                                           alertPreferenceEligibilities: Configuration.shared.opco.isPHI) { (result: Result<AccountDetail, NetworkingError>) in
                            switch result {
                            case .success(let accountDetail):
                                UserDefaults.standard.set(accountDetail.customerNumber, forKey: UserDefaultKeys.customerIdentifier)
                                AccountsStore.shared.customerIdentifier = accountDetail.customerNumber
                                AccountsStore.shared.accountOpco = accountDetail.opcoType ?? Configuration.shared.opco
                                completion(.success(tokenResponse))
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
    
    private static func performLogin(username: String,
                                     password: String,
                                     completion: @escaping (Result<Bool, NetworkingError>) -> ()) {
        fetchLoginToken(username: username,
                        password: password) { (result: (Result<TokenResponse, NetworkingError>)) in
            switch result {
            case .success(let tokenResponse):
                #if os(iOS)
                FirebaseUtility.logEvent(.loginTokenNetworkComplete)
                #endif

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
                        #if os(iOS)
                        FirebaseUtility.logEvent(.loginAccountNetworkComplete)
                        #endif
                        
                        guard let accNumber = accounts.first?.accountNumber else {
                            completion(.failure(.invalidResponse))
                            return
                        }
                        AccountService.fetchAccountDetails(accountNumber: accNumber,
                                                           alertPreferenceEligibilities: Configuration.shared.opco.isPHI) { (result: Result<AccountDetail, NetworkingError>) in
                            switch result {
                            case .success(let accountDetail):
                                UserDefaults.standard.set(accountDetail.customerNumber, forKey: UserDefaultKeys.customerIdentifier)
                                AccountsStore.shared.customerIdentifier = accountDetail.customerNumber
                                AccountsStore.shared.accountOpco = accountDetail.opcoType ?? Configuration.shared.opco
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



