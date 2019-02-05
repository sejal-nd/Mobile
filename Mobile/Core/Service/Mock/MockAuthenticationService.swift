//
//  MockAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

struct MockAuthenticationService: AuthenticationService {
    
    let invalidUsername = "invalid@test.com"
    let invalidPassword = "invalid"
    
    func login(username: String, password: String, stayLoggedIn: Bool) -> Observable<ProfileStatus> {
        if username != invalidUsername && password != invalidPassword {
            MockUser.current = MockUser(username: username)
            return .just(ProfileStatus())
        } else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fnPwdInvalid.rawValue, serviceMessage: "Invalid credentials"))
        }
    }
    
    func validateLogin(username: String, password: String) -> Observable<Void> {
        return .error(ServiceError())
    }
    
    func isAuthenticated() -> Bool {
        return false
    }
    
    func logout() {

    }
    
    func changePassword(currentPassword: String, newPassword: String) -> Observable<Void> {
        if currentPassword != invalidPassword {
            return .just(())
        } else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fNPwdNoMatch.rawValue, serviceMessage: "Invalid current password"))
        }
    }
    
    func changePasswordAnon(username: String,currentPassword: String, newPassword: String) -> Observable<Void> {
        if currentPassword != invalidPassword {
            return .just(())
        } else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.fNPwdNoMatch.rawValue, serviceMessage: "Invalid current password"))
        }
    }
    
    func getMaintenanceMode(postNotification: Bool) -> Observable<Maintenance> {
        let dataFile = MockJSONManager.File.maintenance
        let key = MockAppState.current.maintenanceKey
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func getMinimumVersion() -> Observable<MinimumVersion> {
        return .just(MinimumVersion())
    }
    
    func refreshAuthorization() -> Observable<Void> {
        return .just(())
    }
    
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]> {
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
        
        if identifier == "0000" {
            return Observable.error(ServiceError(serviceCode: ServiceErrorCode.fnAccountNotFound.rawValue))
                .delay(1, scheduler: MainScheduler.instance)
        } else {
            return Observable.just(maskedUsernames)
                .delay(1, scheduler: MainScheduler.instance)
        }
    }
    
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String> {
        if questionResponse.lowercased() == "exelon" {
            return Observable.just("username@email.com")
                .delay(1, scheduler: MainScheduler.instance)
        } else {
            return Observable.error(ServiceError(serviceCode: ServiceErrorCode.fnProfBadSecurity.rawValue))
                .delay(1, scheduler: MainScheduler.instance)
        }
    }
    
    func lookupAccount(phone: String, identifier: String) -> Observable<[AccountLookupResult]> {
        if identifier == "0000" {
            return Observable.error(ServiceError(serviceMessage: "No accounts found"))
                .delay(1, scheduler: MainScheduler.instance)
        } else if identifier == "1111" {
            var accountResults = [AccountLookupResult]()
            accountResults.append(AccountLookupResult.from(
                NSDictionary(dictionary: [
                    "AccountNumber": "1234567890",
                    "StreetNumber": "1268",
                    "ApartmentUnitNumber": "12B"
                    ])
                )!)
            return Observable.just(accountResults)
                .delay(1, scheduler: MainScheduler.instance)
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
            return Observable.just(accountResults)
                .delay(1, scheduler: MainScheduler.instance)
        }
    }
    
    func recoverPassword(username: String) -> Observable<Void> {
        if username.lowercased() == "error" {
            return Observable.error(ServiceError(serviceCode: ServiceErrorCode.fnProfNotFound.rawValue))
                .delay(1, scheduler: MainScheduler.instance)
        } else {
            return Observable.just(())
                .delay(1, scheduler: MainScheduler.instance)
        }
    }
    
}
