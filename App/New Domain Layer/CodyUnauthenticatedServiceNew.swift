//
//  CodyUnauthenticatedServiceNew.swift
//  BGE
//
//  Created by Cody Dillon on 4/13/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct CodyUnauthenticatedServiceNew {
    
    static func changePassword(request: ChangePasswordRequest, completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .passwordChange(request: request)) { (result: Result<VoidDecodable, NetworkingError>) in
            switch result {
            case .success(let data):
                print("changePassword SUCCESS: \(data)")
                completion(.success(()))
                
            case .failure(let error):
                print("changePassword FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    static func lookupAccount(request: AccountLookupRequest, completion: @escaping (Result<NewAccountLookupResult, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .accountLookup(encodable: request)) { (result: Result<NewAccountLookupResult, NetworkingError>) in
            switch result {
            case .success(let data):
                print("lookupAccount SUCCESS: \(data)")
                completion(.success(data))

            case .failure(let error):
                print("lookupAccount FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    static func recoverUsername(request: RecoverUsernameRequest, completion: @escaping (Result<String, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .recoverUsername(encodable: request)) { (result: Result<String, NetworkingError>) in
            switch result {
            case .success(let data):
                print("recoverUsername SUCCESS: \(data)")
                completion(.success(data))

            case .failure(let error):
                print("recoverUsername FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    static func recoverMaskedUsername(request: RecoverMaskedUsernameRequest, completion: @escaping (Result<NewForgotMaskedUsername, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .recoverUsername(encodable: request)) { (result: Result<NewForgotMaskedUsername, NetworkingError>) in
            switch result {
            case .success(let data):
                print("recoverMaskedUsername SUCCESS: \(data)")
                completion(.success(data))

            case .failure(let error):
                print("recoverMaskedUsername FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    static func recoverPassword(request: RecoverPasswordRequest, completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        
        NetworkingLayer.request(router: .recoverPassword(encodable: request)) { (result: Result<VoidDecodable, NetworkingError>) in
            switch result {
            case .success(let data):
                print("recoverPassword SUCCESS: \(data)")
                completion(.success(()))
                
            case .failure(let error):
                print("recoverPassword FAIL: \(error)")
                completion(.failure(error))
            }
        }
    }
}
