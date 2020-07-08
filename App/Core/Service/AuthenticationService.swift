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
    
    func getMaintenanceMode(postNotification: Bool) -> Observable<Maintenance>
        
    /// Attempt to recover a username by providing a phone number and identifier. If the
    ///     phone/identifier match an account, an array of ForgotUsernameMasked
    ///     objects is returned, which will contain a list of masked usernames
    ///     and security question info.
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]>
    
    /// Attempt to recover a username by providing a security question answer. If the
    ///     question/id are correct, the response will contain an unmasked username
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    ///   - questionId: the question id
    ///   - questionResponse: the question response
    ///   - cipher: the cipher for the username (supplied from masked username)
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String>
    
    /// Look up an account number by phone and id. If the
    ///     phone/id match an account, an array of AccountLookupResult objects
    ///     is returned.
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin) - varies by opco.
    func lookupAccount(phone: String, identifier: String) -> Observable<[AccountLookupResult]>
    
    #if os(iOS)
    /// Reset a password by providing your username
    ///
    /// - Parameters:
    ///   - username: the username associated with the account.
    func recoverPassword(username: String) -> Observable<Void>
    #endif
}

extension AuthenticationService {
    func getMaintenanceMode(postNotification: Bool = true) -> Observable<Maintenance> {
        return getMaintenanceMode(postNotification: postNotification)
    }
}
