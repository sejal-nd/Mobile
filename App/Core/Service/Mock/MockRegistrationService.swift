//
//  MockRegistrationService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

struct MockRegistrationService: RegistrationService {
    
    func createNewAccount(username: String, password: String, accountNum: String?, identifier: String, phone: String, question1: String, answer1: String, question2: String, answer2: String, question3: String, answer3: String, isPrimary: String, isEnrollEBill: String) -> Observable<Void> {
        return .just(())
    }
    
    func checkForDuplicateAccount(_ username: String) -> Observable<Void> {
        return .just(())
    }
    
    func loadSecretQuestions() -> Observable<[String]> {
        return .just(["Hello", "Hi", "Howdy", "Aloha", "Guten tag"])
    }
    
    func validateAccountInformation(_ identifier: String, phone: String, accountNum: String?, dueAmount: String?, dueDate: String?) -> Observable<[String : Any]> {
        if phone.count == 10 && identifier.count == 4 {
            return .just([:])
        } else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue))
        }
    }
    
    func resendConfirmationEmail(_ username: String) -> Observable<Void> {
        return .just(())
    }
    
    func validateConfirmationEmail(_ guid: String) -> Observable<Void> {
        return .just(())
    }

}
