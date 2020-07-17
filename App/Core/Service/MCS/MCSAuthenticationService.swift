//
//  MCSAuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

private enum OAuthQueryParams: String {
    case username = "username"
    case password = "password"
    case encode = "encode"
}

private enum ChangePasswordParams: String {
    case oldPassword = "old_password"
    case newPassword = "new_password"
}

private enum AnonChangePasswordParams: String {
    case username = "username"
    case oldPassword = "old_password"
    case newPassword = "new_password"
}

fileprivate extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}

struct MCSAuthenticationService : AuthenticationService {

    #if os(iOS)
    func changePassword(currentPassword: String, newPassword: String) -> Observable<Void> {
        
        let params = [
            ChangePasswordParams.oldPassword.rawValue: currentPassword,
            ChangePasswordParams.newPassword.rawValue: newPassword
        ]
        
        return MCSApi.shared.put(pathPrefix: .auth, path: "profile/password", params: params)
            .mapTo(())
    }
    
    func changePasswordAnon(username: String, currentPassword: String, newPassword: String) -> Observable<Void> {
        
        let params = [
            AnonChangePasswordParams.username.rawValue: username,
            AnonChangePasswordParams.oldPassword.rawValue: currentPassword,
            AnonChangePasswordParams.newPassword.rawValue: newPassword
        ]
        
        return MCSApi.shared.put(pathPrefix: .anon, path: "profile/password", params: params)
            .mapTo(())
    }
    
    func recoverPassword(username: String) -> Observable<Void> {
        let params = ["username" : username]
        return MCSApi.shared.post(pathPrefix: .anon, path: "recover/password", params: params)
            .mapTo(())
    }
    #endif

}
