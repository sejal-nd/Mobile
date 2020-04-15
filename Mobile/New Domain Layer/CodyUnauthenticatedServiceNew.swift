//
//  CodyUnauthenticatedServiceNew.swift
//  BGE
//
//  Created by Cody Dillon on 4/13/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct CodyUnauthenticatedServiceNew {
    static func changePassword(username: String, currentPassword: String, newPassword: String, completion: @escaping (Result<Void, NetworkingError>) -> ()) {
        
        let params = ["username": username,
                      "old_password": currentPassword,
                      "new_password": newPassword]
        
        do {
            let httpBody = try JSONSerialization.data(withJSONObject: params)
            
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
            completion(.failure(.decodingError))
        }
    }
}
