//
//  RegistrationServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct RegistrationServiceNew {
    
//    old way
//    static func createAccount(request: NewAccountRequest, completion: @escaping (Result<Void, Error>) -> ()) {
//        NetworkingLayer.request(router: .registration(encodable: request)) { (result: Result<VoidDecodable, NetworkingError>) in
//            switch result {
//            case .success(_):
//                completion(.success(()))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
//    pass completion handler directly to NetworkingLayer
    static func createAccount(request: NewAccountRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registration(encodable: request), completion: completion)
    }
    
//    wrap handler so you can do something with the response like save to keychain
//        static func createAccount(request: NewAccountRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
//            NetworkingLayer.request(router: .registration(encodable: request)) { (result: Result<VoidDecodable, NetworkingError>) in
//                switch result {
//                case .success(let data):
//                    // do something with response here
//                    completion(.success(data))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
}
