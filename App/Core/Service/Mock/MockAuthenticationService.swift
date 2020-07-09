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
    
    func refreshAuthorization() -> Observable<Void> {
        return .just(())
    }
    
    func recoverPassword(username: String) -> Observable<Void> {
        if username.lowercased() == "error" {
            return Observable.error(ServiceError(serviceCode: ServiceErrorCode.fnProfNotFound.rawValue))
                .delay(.seconds(1), scheduler: MainScheduler.instance)
        } else {
            return Observable.just(())
                .delay(.seconds(1), scheduler: MainScheduler.instance)
        }
    }
    
}
