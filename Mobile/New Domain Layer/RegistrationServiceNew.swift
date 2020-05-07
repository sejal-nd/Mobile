//
//  RegistrationServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct RegistrationServiceNew {
    static func createAccount(request: NewAccountRequest, completion: @escaping (Result<Void, Error>) -> ()) {
        NetworkingLayer.request(router: .registration) { (result: Result<VoidDecodable, NetworkingError>) in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func checkDuplicateRegistration(
}
