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
        
        if opCo != .bge {
            params["question3"] = question3
            params["answer3"] = answer3
        }
        
        if let accountNum = accountNum, !accountNum.isEmpty {
            params["account_num"] = accountNum
        }
        
        return MCSApi.shared.post(path: "anon_\(MCSApi.API_VERSION)/\(opCo.rawValue)/registration", params: params)
            .mapTo(())
    }
    
    func checkForDuplicateAccount(_ username: String) -> Observable<Void> {
        let opCo = Environment.shared.opco.rawValue
        let params = ["username": username] as [String : Any]
        return MCSApi.shared.post(path: "anon_\(MCSApi.API_VERSION)/\(opCo)/registration/duplicate", params: params)
            .mapTo(())
    }
    
    func loadSecretQuestions() -> Observable<[String]> {
        let opCo = Environment.shared.opco.rawValue
        return MCSApi.shared.get(path: "anon_\(MCSApi.API_VERSION)/\(opCo)/registration/questions")
            .map { json in
                guard let questions = json as? [String] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return questions
        }
    }
    
    func validateAccountInformation(_ identifier: String,
                                    phone: String,
                                    accountNum: String?) -> Observable<[String: Any]> {
        let opCo = Environment.shared.opco.rawValue.uppercased()
        
        var params = ["phone": phone] as [String : Any]
        params["identifier"] = identifier
        
        if let accountNum = accountNum, !accountNum.isEmpty {
            params["account_num"] = accountNum
        }
        
        return MCSApi.shared.post(path: "anon_\(MCSApi.API_VERSION)/\(opCo)/registration/validate", params: params)
            .map { json in
                guard let dict = json as? [String : Any] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return dict
        }
    }
    
    func resendConfirmationEmail(_ username: String) -> Observable<Void> {
        let opCo = Environment.shared.opco.displayString.uppercased()
        let params = ["username": username] as [String: Any]
        return MCSApi.shared.post(path: "anon_\(MCSApi.API_VERSION)/\(opCo)/registration/confirmation", params: params)
            .mapTo(())
    }

    func validateConfirmationEmail(_ guid: String) -> Observable<Void> {
        let opCo = Environment.shared.opco.displayString.uppercased()
        let params = ["guid": guid] as [String: Any]
        return MCSApi.shared.put(path: "anon_\(MCSApi.API_VERSION)/\(opCo)/registration/confirmation", params: params)
            .mapTo(())
    }
    
    func recoverPassword(_ username: String) -> Observable<Void> {
        let opCo = Environment.shared.opco.rawValue
        let params = ["username": username] as [String: Any]
        return MCSApi.shared.post(path: "anon_\(MCSApi.API_VERSION)/\(opCo)/recover/password", params: params)
            .mapTo(())
    }
}