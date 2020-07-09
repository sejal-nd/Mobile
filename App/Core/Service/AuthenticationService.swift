//
//  AuthenticationService.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

/// The AuthenticationService protocol defines the interface necessary
/// to deal with authentication related service routines such as 
/// login/logout.
protocol AuthenticationService {
    
    #if os(iOS)
    /// Authenticate a user with the supplied credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    func login(username: String, password: String, stayLoggedIn: Bool) -> Observable<ProfileStatus>
    
    /// Validate login credentials
    ///
    /// - Parameters:
    ///   - username: the suername to authenticate with.
    ///   - password: the password to authenticate with.
    func validateLogin(username: String, password: String) -> Observable<Void>
    #endif
    
    /// Check if the user is authenticated
    func isAuthenticated() -> Bool
    
    /// Log out the currently logged in user
    ///
    /// Note that this operation can and should have the side effect of removing
    /// any cached information related to the user, either in memory or on disk.
    func logout()
    
    #if os(iOS)
    /// Change the currently logged in users password.
    ///
    /// - Parameters:
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    func changePassword(currentPassword: String, newPassword: String) -> Observable<Void>
    
    /// Change the password for a given user. Used for temp password changes.
    ///
    /// - Parameters:
    ///   - username: current user's username
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    func changePasswordAnon(username: String, currentPassword: String, newPassword: String) -> Observable<Void>
    #endif

    #if os(iOS)
    /// Reset a password by providing your username
    ///
    /// - Parameters:
    ///   - username: the username associated with the account.
    func recoverPassword(username: String) -> Observable<Void>
    #endif
}
