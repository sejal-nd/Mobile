//
//  MCSRegistrationService.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MCSRegistrationService: RegistrationService {

    func createNewAccount(username: String,
                          password: String,
                          accountNum: String?,
                          identifier: String,
                          phone: String,
                          question1: String,
                          answer1: String,
                          question2: String,
                          answer2: String,
                          question3: String,
                          answer3: String,
                          isPrimary: String,
                          isEnrollEBill: String) -> Observable<Void> {
        let opCo = Environment.shared.opco
        
        var params = ["username": username,
                      "password": password,
                      "identifier": identifier,
                      "phone": phone,
                      "question1": question1,
                      "answer1": answer1,
                      "question2": question2,
                      "answer2": answer2,
                      "set_primary": isPrimary,
                      "enroll_ebill": isEnrollEBill] as [String : Any]
        
        if opCo != .bge && opCo != .comEd {
            params["question3"] = question3
            params["answer3"] = answer3
        }
        
        if let accountNum = accountNum, !accountNum.isEmpty {
            params["account_num"] = accountNum
        }
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "registration", params: params)
            .mapTo(())
    }
    
    func loadSecretQuestions() -> Observable<[String]> {
        return MCSApi.shared.get(pathPrefix: .anon, path: "registration/questions")
            .map { json in
                guard let questions = json as? [String] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return questions
            }
    }

    func resendConfirmationEmail(_ username: String) -> Observable<Void> {
        let params = ["username": username] as [String: Any]
        return MCSApi.shared.post(pathPrefix: .anon, path: "registration/confirmation", params: params)
            .mapTo(())
    }

    func validateConfirmationEmail(_ guid: String) -> Observable<Void> {
        let params = ["guid": guid] as [String: Any]
        return MCSApi.shared.put(pathPrefix: .anon, path: "registration/confirmation", params: params)
            .mapTo(())
    }
    
}
