//
//  MockRegistrationService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

struct MockRegistrationService: RegistrationService {
    
    func createNewAccount(username: String, password: String, accountNum: String?, identifier: String, phone: String, question1: String, answer1: String, question2: String, answer2: String, question3: String, answer3: String, isPrimary: String, isEnrollEBill: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func checkForDuplicateAccount(_ username: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func loadSecretQuestions(_ completion: @escaping (ServiceResult<[String]>) -> Void) {
        
    }
    
    func validateAccountInformation(_ identifier: String, phone: String, accountNum: String?, completion: @escaping (ServiceResult<[String : Any]>) -> Void) {
        
    }
    
    func resendConfirmationEmail(_ username: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func validateConfirmationEmail(_ guid: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func recoverPassword(_ username: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
}
