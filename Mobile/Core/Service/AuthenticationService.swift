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
    
    /// Authenticate a user with the supplied credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    ///   - completion: the completion block to execute upon completion. 
    ///     The ServiceResult that is provided will contain a tuple with the
    ///     ProfileStatus and AccountDetail on success, or the error on failure.
    func login(username: String, password: String, stayLoggedIn: Bool) -> Observable<(ProfileStatus, AccountDetail)>
    
    /// Validate login credentials
    ///
    /// - Parameters:
    ///   - username: the suername to authenticate with.
    ///   - password: the password to authenticate with.
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain the ProfileStatus on success,
    ///     or the error on failure.
    func validateLogin(username: String, password: String) -> Observable<Void>
    
    /// Check if the user is authenticated
    func isAuthenticated() -> Bool
    
    /// Log out the currently logged in user
    ///
    /// Note that this operation can and should have the side effect of removing
    /// any cached information related to the user, either in memory or on disk.
    func logout()
    
    /// Change the currently logged in users password.
    ///
    /// - Parameters:
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    ///   - completion: the completion block to execute upon completion. The
    ///     ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func changePassword(currentPassword: String, newPassword: String) -> Observable<Void>
    
    /// Change the password for a given user. Used for temp password changes.
    ///
    /// - Parameters:
    ///   - username: current user's username
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    ///   - completion: the completion block to execute upon completion. The
    ///     ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func changePasswordAnon(username: String, currentPassword: String, newPassword: String) -> Observable<Void>
    
    func getMaintenanceMode() -> Observable<Maintenance>
    
    func getMinimumVersion() -> Observable<MinimumVersion>
    
    /// Attempt to recover a username by providing a phone number and identifier.
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    ///   - completion: the completion block to execute upon completion. If the 
    ///     phone/identifier match an account, an array of ForgotUsernameMasked 
    ///     objects is returned, which will contain a list of masked usernames 
    ///     and security question info.
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]>
    
    /// Attempt to recover a username by providing a security question answer
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    ///   - questionId: the question id
    ///   - questionResponse: the question response
    ///   - cipher: the cipher for the username (supplied from masked username)
    ///   - completion: the completion block to execute upon completion. If the
    ///     question/id are correct, the response will contain an unmasked username
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String>
    
    /// Look up an account number by phone and id
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin) - varies by opco.
    ///   - completion: the completion block to execute upon completion. If the
    ///     phone/id match an account, an array of AccountLookupResult objects
    ///     is returned.
    func lookupAccount(phone: String, identifier: String) -> Observable<[AccountLookupResult]>
    
    /// Reset a password by providing your username
    ///
    /// - Parameters:
    ///   - username: the username associated with the account.
    ///   - completion: the completion block to execute upon completion
    ///     of the password reset initiation process
    func recoverPassword(username: String) -> Observable<Void>
}
