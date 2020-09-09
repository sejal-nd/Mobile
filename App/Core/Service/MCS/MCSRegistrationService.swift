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

    func createNewAccount(firstName: String?,
                          lastName: String?,
                          username: String,
                          password: String,
                          nickname: String?,
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
        
        if opCo.isPHI {
            if let firstname = firstName {
                params["FirstName"] = firstname
            }
            if let lastname = lastName {
                params["LastName"] = lastname
            }
            if let nickName = nickname {
                params["nickname"] = nickName
            }
        }
        
        if opCo != .bge && !RemoteConfigUtility.shared.bool(forKey: .hasNewRegistration) {
            params["question3"] = question3
            params["answer3"] = answer3
        }
        
        if let accountNum = accountNum, !accountNum.isEmpty {
            params["account_num"] = accountNum
        }
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "registration", params: params)
            .mapTo(())
    }
    
    func checkForDuplicateAccount(_ username: String) -> Observable<Void> {
        let params = ["username": username] as [String : Any]
        return MCSApi.shared.post(pathPrefix: .anon, path: "registration/duplicate", params: params)
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
    
    func validateAccountInformation(_ identifier: String,
                                    phone: String,
                                    accountNum: String?,
                                    dueAmount: String?,
                                    dueDate: String?) -> Observable<[String: Any]> {
        var params = ["phone": phone] as [String : Any]
        params["identifier"] = identifier
        
        if let accountNum = accountNum, !accountNum.isEmpty {
            params["account_num"] = accountNum
        }
        if let dueDate = dueDate, !dueDate.isEmpty {
            params["bill_date"] = dueDate
        }
        if let dueAmount = dueAmount, !dueAmount.isEmpty {
             params["amount_due"] = dueAmount
        }
        
        return MCSApi.shared.post(pathPrefix: .anon, path: "registration/validate", params: params)
            .map { json in
                guard let dict = json as? [String : Any] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return dict
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
