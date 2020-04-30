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
    static func login(username: String,
                      password: String,
                      completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        if Environment.shared.environmentName != .aut {
            performLogin(username: username, password: password, completion: completion)
        } else {
            performLoginMock(username: username, completion: completion)
        }
    }
    
    static func fetchAccountDetails(accountNumber: String, payments: Bool = true, programs: Bool = true, budgetBilling: Bool = true) {
        
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
                
                // fetch accounts todo
                
                print("NetworkTest 6 SUCCESS: \(data.address) BREAK")
//                completion(.success(()))
                
                
            //                       completion(.success(data.min))
                
                NetworkTest.shared.wallet()
                
                NetworkTest.shared.payment(accountNumber: data.accountNumber)
                
                AuthenticatedService.fetchAlertBanner(bannerOnly: true, stormOnly: false)
                
            case .failure(let error):
                print("NetworkTest 6 FAIL: \(error)")
//                completion(.failure(error))
            }
        }
    }
    
    static func fetchAlertBanner(bannerOnly: Bool, stormOnly: Bool) {
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
                print("NetworkTest 13 SUCCESS: \(data) BREAK \(data.alerts.first?.title)")
            case .failure(let error):
                print("NetworkTest 13 FAIL: \(error)")
            }
        }
    }
    
    
    
    // MARK: Private methods
    
    private static func performLogin(username: String,
                                     password: String,
                                     completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        print("username: \(username)")
        print("PW: \(password)")
        
        guard let username = username.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved),
            let password = password.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) else {
                print("FAIL DATA")
                return
        }
        
//        let postDataString = "username=\(Environment.shared.opco.rawValue.uppercased())\\\(username)&password=\(password)"
//        let httpBody = postDataString.data(using: .utf8)
        //        ServiceLayer.logJSON(router: .fetchToken(httpBody: postDataString.data(using: .utf8))) { (result: Result<String, Error>) in
        //                               switch result {
        //                               case .success(let data):
        //
        //
        //
        //                                print("NetworkTest 3 JSON SUCCESS: \(data) BREAK")
        //            //                       completion(.success(data.min))
        //                               case .failure(let error):
        //                                   print("NetworkTest 3 FAIL: \(error)")
        //                                   completion(.failure(error))
        //                               }
        //        }
        
        let encodedObject = SAMLRequest(username: username, password: password)
        
        NetworkingLayer.request(router: .fetchSAMLToken(encodable: encodedObject)) { (result: Result<NewSAMLToken, NetworkingError>) in
            switch result {
            case .success(let data):
                guard let token = data.token else { return }
                
                NetworkingLayer.request(router: .exchangeSAMLToken(token: token)) { (result: Result<NewJWTToken, NetworkingError>) in
                    switch result {
                    case .success(let newJWTToken):
                        
                        // todo persist jwt token for keep me signed in
                        guard let token = newJWTToken.token else {
                            print("FAILED NO TOKEN")
                            return
                        }
                        UserSession.shared.token = token
                        
                        print("NetworkTest 4 SUCCESS: \(newJWTToken.token) BREAK")
                        
                        NetworkingLayer.request(router: .accounts) { (result: Result<NewAccounts, NetworkingError>) in
                            switch result {
                            case .success(let data):
                                
                                // fetch accounts todo
                                
                                print("NetworkTest 5 SUCCESS: \(data.accounts.first?.accountNumber) BREAK")
                                
                                guard let accNumber = data.accounts.first?.accountNumber else { return }
                                
                                AuthenticatedService.fetchAccountDetails(accountNumber: accNumber)
                                
                                completion(.success(()))
                                
                                
                            //                       completion(.success(data.min))
                            case .failure(let error):
                                print("NetworkTest 5 FAIL: \(error)")
                                completion(.failure(error))
                            }
                        }
                        
                    //                       completion(.success(data.min))
                    case .failure(let error):
                        print("NetworkTest 4 FAIL: \(error)")
                        completion(.failure(error))
                    }
                }
                
                
                
                print("NetworkTest 3 SUCCESS: \(data.token) BREAK")
            //                       completion(.success(data.min))
            case .failure(let error):
                print("NetworkTest 3 FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private static func performLoginMock(username: String,
                                         completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        print("LOGIN MOCK")
        // SET MOCK USER
        UserSession.shared.token = username
        
        NetworkingLayer.request(router: .accounts) { (result: Result<NewAccounts, NetworkingError>) in
            switch result {
            case .success(let data):
                
                // fetch accounts todo
                
                print("NetworkTest 5 MOCK SUCCESS: \(data.accounts.first?.accountNumber) BREAK")
                completion(.success(()))
                
                
            //                       completion(.success(data.min))
            case .failure(let error):
                print("NetworkTest 5 MOCK FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
}

fileprivate extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
