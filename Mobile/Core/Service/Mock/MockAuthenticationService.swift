//
//  MockAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MockAuthenticationService : AuthenticationService {
    
    let validUsername = "valid@test.com"
    
    func login(_ username: String, password: String, completion: @escaping (ServiceResult<String>) -> Void) {
        
        if(username == validUsername) {
            completion(ServiceResult.Success(""))
        } else {
            completion(ServiceResult.Failure(ServiceError.Custom(code: "FN_INVALID", description: "Invalid credentials")))
        }
        
    }
    
    func logout(completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Success())
    }
    
    func changePassword(_ currentPassword: String, newPassword: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
}
