//
//  RegistrationServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct RegistrationServiceNew {
    static func createAccount(request: NewAccountRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registration(encodable: request), completion: completion)
    }
    
    static func checkDuplicateRegistration(request: UsernameRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .checkDuplicateRegistration(encodable: request), completion: completion)
    }
    
    static func getRegistrationQuestions(completion: @escaping (Result<[String], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registrationQuestions, completion: completion)
    }
    
    static func validateRegistration(request: ValidateAccountRequest, completion: @escaping (Result<ValidatedAccount, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .validateRegistration(encodable: request), completion: completion)
    }
    
    static func sendConfirmationEmail(request: UsernameRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .sendConfirmationEmail(encodable: request), completion: completion)
    }
    
    static func validateConfirmationEmail(request: GuidRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .validateConfirmationEmail(encodable: request), completion: completion)
    }
}
