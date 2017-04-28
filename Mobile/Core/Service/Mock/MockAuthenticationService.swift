//
//  MockAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

struct MockAuthenticationService : AuthenticationService {
    
    let validUsername = "valid@test.com"
    let validCurrentPassword = "Password1"
    
    func login(_ username: String, password: String, completion: @escaping (ServiceResult<ProfileStatus>) -> Void) {
        
        if(username == validUsername) {
            completion(ServiceResult.Success(ProfileStatus()))
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnPwdInvalid.rawValue, serviceMessage: "Invalid credentials")))
        }
        
    }
    
    func logout(completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Success())
    }
    
    func changePassword(_ currentPassword: String, newPassword: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        if currentPassword == validCurrentPassword {
            completion(ServiceResult.Success())
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FNPwdNoMatch.rawValue, serviceMessage: "Invalid current password")))
        }
    }
    
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?, completion: @escaping (_ result: ServiceResult<[ForgotUsernameMasked]>) -> Void) {
        var maskedUsernames = [ForgotUsernameMasked]()
        let usernames = [
            NSDictionary(dictionary: [
                "email": "userna**********",
                "question": "What is your mother's maiden name?",
                "question_id": 1
                ]),
//                NSDictionary(dictionary: [
//                    "email": "m**********g@mindgrub.com",
//                    "question": "What is your mother's maiden name?",
//                    "question_id": 4
//                ]),
//                NSDictionary(dictionary: [
//                    "email": "m**********g@icloud.com",
//                    "question": "What street did you grow up on?",
//                    "question_id": 3
//                ])
        ]
        for user in usernames {
            if let mockModel = ForgotUsernameMasked.from(user) {
                maskedUsernames.append(mockModel)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            if identifier == "0000" {
                completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnAccountNotFound.rawValue)))
            } else {
                completion(ServiceResult.Success(maskedUsernames))
            }
        }
    }
    
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String, completion: @escaping (ServiceResult<String>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            if questionResponse.lowercased() == "exelon" {
                completion(ServiceResult.Success("username@email.com"))
            } else {
                completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnProfBadSecurity.rawValue)))
            }
        }

    }
    
    func lookupAccount(phone: String, identifier: String, completion: @escaping (ServiceResult<[AccountLookupResult]>) -> Void) {

        

        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            if identifier == "0000" {
                completion(ServiceResult.Failure(ServiceError(serviceMessage: "No accounts found")))
                return
            } else if identifier == "1111" {
                var accountResults = [AccountLookupResult]()
                accountResults.append(AccountLookupResult.from(
                    NSDictionary(dictionary: [
                        "AccountNumber": "1234567890",
                        "StreetNumber": "1268",
                        "ApartmentUnitNumber": "12B"
                    ])
                )!)
                completion(ServiceResult.Success(accountResults))
            } else {
                var accountResults = [AccountLookupResult]()
                let accounts = [
                    NSDictionary(dictionary: [
                        "AccountNumber": "1234567890",
                        "StreetNumber": "1268",
                        "ApartmentUnitNumber": "12B"
                    ]),
                    NSDictionary(dictionary: [
                        "AccountNumber": "9876543219",
                        "StreetNumber": "6789",
                        "ApartmentUnitNumber": "99A"
                    ]),
                    NSDictionary(dictionary: [
                        "AccountNumber": "1111111111",
                        "StreetNumber": "999",
                    ])
                ]
                for account in accounts {
                    if let mockModel = AccountLookupResult.from(account) {
                        accountResults.append(mockModel)
                    }
                }
                completion(ServiceResult.Success(accountResults))
            }
        }
    }
    
    func recoverPassword(username: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            if username.lowercased() == "error" {
                completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.FnProfNotFound.rawValue)))
            } else {
                completion(ServiceResult.Success())
            }
        }
    }

}
