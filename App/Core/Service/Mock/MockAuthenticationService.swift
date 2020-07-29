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
            .do(onNext: { maintenance in
                if maintenance.allStatus {
                    NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: maintenance)
                }
            })
    }
    
    func getMinimumVersion() -> Observable<MinimumVersion> {
        return .just(MinimumVersion())
    }
    
    func refreshAuthorization() -> Observable<Void> {
        return .just(())
    }
    
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]> {
        if identifier == "0000" {
            return Observable.error(ServiceError(serviceCode: ServiceErrorCode.fnAccountNotFound.rawValue))
                .delay(.seconds(1), scheduler: MainScheduler.instance)
        }
        
        return MockJSONManager.shared.rx.mappableArray(fromFile: .recoverUsername, key: .default)
    }
    
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String> {
        if questionResponse.lowercased() == "exelon" {
            return Observable.just("username@email.com")
                .delay(.seconds(1), scheduler: MainScheduler.instance)
        } else {
            return Observable.error(ServiceError(serviceCode: ServiceErrorCode.fnProfBadSecurity.rawValue))
                .delay(.seconds(1), scheduler: MainScheduler.instance)
        }
    }
    
    func lookupAccount(phone: String, identifier: String) -> Observable<[AccountLookupResult]> {
        let key: MockDataKey
        switch identifier {
        case "0000":
            return .error(ServiceError(serviceMessage: "No accounts found"))
        case "1111":
            key = .acctLookup1
        default:
            key = .default
        }
        
        return MockJSONManager.shared.rx.mappableArray(fromFile: .accountLookup, key: key)
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