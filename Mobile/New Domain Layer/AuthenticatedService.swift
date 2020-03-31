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
                      completion: @escaping (Result<Void, Error>) -> ()) {
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
        
        
        ServiceLayer.request(router: .accountDetails(accountNumber: accountNumber, queryString: queryString)) { (result: Result<NewAccountDetails, Error>) in
            switch result {
            case .success(let data):
                
                // fetch accounts todo
                
                print("NetworkTest 6 SUCCESS: \(data.address) BREAK")
//                completion(.success(()))
                
                
            //                       completion(.success(data.min))
                
                NetworkTest.shared.wallet()
                
            case .failure(let error):
                print("NetworkTest 6 FAIL: \(error)")
//                completion(.failure(error))
            }
        }
    }
    
    
    
    
    
    // MARK: Private methods
    
    private static func performLogin(username: String,
                                     password: String,
                                     completion: @escaping (Result<Void, Error>) -> ()) {
        print("username: \(username)")
        print("PW: \(password)")
        
        guard let username = username.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved),
            let password = password.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) else {
                print("FAIL DATA")
                return
        }
        
        let postDataString = "username=\(Environment.shared.opco.rawValue.uppercased())\\\(username)&password=\(password)"
        let httpBody = postDataString.data(using: .utf8)
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
        
        ServiceLayer.request(router: .fetchSAMLToken(httpBody: httpBody)) { (result: Result<NewSAMLToken, Error>) in
            switch result {
            case .success(let data):
                guard let token = data.token else { return }
                
                ServiceLayer.request(router: .exchangeSAMLToken(token: token)) { (result: Result<NewJWTToken, Error>) in
                    switch result {
                    case .success(let newJWTToken):
                        
                        // todo persist jwt token for keep me signed in
                        guard let token = newJWTToken.token else {
                            print("FAILED NO TOKEN")
                            return
                        }
                        UserSession.shared.token = token
                        
                        print("NetworkTest 4 SUCCESS: \(newJWTToken.token) BREAK")
                        
                        ServiceLayer.request(router: .accounts) { (result: Result<NewAccounts, Error>) in
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
                                         completion: @escaping (Result<Void, Error>) -> ()) {
        print("LOGIN MOCK")
        // SET MOCK USER
        UserSession.shared.token = username
        
        ServiceLayer.request(router: .accounts) { (result: Result<NewAccounts, Error>) in
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
