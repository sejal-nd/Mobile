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
        
        do {
            let httpBody = try JSONEncoder().encode(request)
            ServiceLayer.request(router: .passwordChange(httpBody: httpBody)) { (result: Result<VoidDecodable, NetworkingError>) in
                switch result {
                case .success(let data):
                    print("changePassword SUCCESS: \(data)")
                    completion(.success(()))
                    
                case .failure(let error):
                    print("changePassword FAIL: \(error)")
                    completion(.failure(error))
                }
            }
        } catch let error {
            print("changePassword encdoing error: \(error)")
            completion(.failure(.encodingError))
        }
    }
    
    static func lookupAccount(request: AccountLookupRequest, completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        do {
            let httpBody = try JSONEncoder().encode(request)
//            ServiceLayer.request(router: .passwordChange(httpBody: httpBody)) { (result: Result<NewAccountLookupResult, NetworkingError>) in
//                switch result {
//                case .success(let data):
//                    print("changePassword SUCCESS: \(data)")
//                    completion(.success(()))
//
//                case .failure(let error):
//                    print("changePassword FAIL: \(error)")
//                    completion(.failure(error))
//                }
//            }
        } catch let error {
            print("lookupAccount encdoing error: \(error)")
            completion(.failure(.encodingError))
        }
    }
}
