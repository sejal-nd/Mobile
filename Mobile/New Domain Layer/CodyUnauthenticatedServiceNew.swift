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
        
        ServiceLayer.request(router: .passwordChange(encodable: request)) { (result: Result<VoidDecodable, NetworkingError>) in
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
    
    static func lookupAccount(request: AccountLookupRequest, completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        
        ServiceLayer.request(router: .accountLookup(encodable: request)) { (result: Result<NewAccountLookupResult, NetworkingError>) in
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
}
