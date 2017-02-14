//
//  AuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// The AuthenticationService protocol defines the interface necessary
/// to deal with authentication related service routines such as 
/// login/logout.
protocol AuthenticationService {
    
    /// Authenticate a user with the supplied credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    ///   - completion: the completion block to execute upon completion. 
    ///     The ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func login(username: String, password: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void)
    
    
    /// Log out the currently logged in user
    ///
    /// Note that this operation can and should have the side effect of
    ///
    /// - Parameter completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will econtain the user id on success,
    ///     or the error on failure.
    func logout(completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void)
    
    
    /// Change the currently logged in users password.
    ///
    /// - Parameters:
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    ///   - completion: the completion block to execute upon completion. The
    ///     ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void)
}
