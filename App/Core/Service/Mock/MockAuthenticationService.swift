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
    
}
