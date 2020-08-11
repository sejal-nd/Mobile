//
//  RegistrationServiceNew.swift
//  Mobile
//
//  Created by Cody Dillon on 5/7/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum RegistrationService {
    static func createAccount(request: NewAccountRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registration(request: request), completion: completion)
    }
    
    static func checkDuplicateRegistration(request: UsernameRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .checkDuplicateRegistration(request: request), completion: completion)
    }
    
    static func getRegistrationQuestions(completion: @escaping (Result<[String], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registrationQuestions, completion: completion)
    }
    
    static func validateRegistration(request: ValidateAccountRequest, completion: @escaping (Result<ValidatedAccountResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .validateRegistration(request: request), completion: completion)
    }
    
    static func sendConfirmationEmail(request: UsernameRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .sendConfirmationEmail(request: request), completion: completion)
    }
    
    static func validateConfirmationEmail(request: GuidRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .validateConfirmationEmail(request: request), completion: completion)
    }
}
