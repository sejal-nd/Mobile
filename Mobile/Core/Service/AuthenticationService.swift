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
    ///     The ServiceResult that is provided will contain the ProfileStatus on success,
    ///     or the error on failure.
    func login(_ username: String, password: String, stayLoggedIn: Bool, completion: @escaping (_ result: ServiceResult<ProfileStatus>) -> Void)
    
    
    /// Validate login credentials
    ///
    /// - Parameters:
    ///   - username: the suername to authenticate with.
    ///   - password: the password to authenticate with.
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain the ProfileStatus on success,
    ///     or the error on failure.
    func validateLogin(_ username: String, password: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    
    /// Check if the application is authenticated
    func isAuthenticated() -> Bool
    
    
    /// Attempt to refresh the authorization token.
    ///
    /// - Parameter completion: the completion block to execute upon completion.
    func refreshAuthorization(completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Log out the currently logged in user
    ///
    /// Note that this operation can and should have the side effect of removing
    /// any cached information related to the user, either in memory or on disk.
    ///
    /// - Parameter completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will econtain the user id on success,
    ///     or the error on failure.
    func logout(completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Change the currently logged in users password.
    ///
    /// - Parameters:
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    ///   - completion: the completion block to execute upon completion. The
    ///     ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func changePassword(_ currentPassword: String, newPassword: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Change the password for a given user. Used for temp password changes.
    ///
    /// - Parameters:
    ///   - username: current user's username
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    ///   - completion: the completion block to execute upon completion. The
    ///     ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func changePasswordAnon(_ username: String, currentPassword: String, newPassword: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    
    func getMaintenanceMode(completion: @escaping(_ result: ServiceResult<Maintenance>) -> Void)
    
    /// Attempt to recover a username by providing a phone number and identifier.
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    ///   - completion: the completion block to execute upon completion. If the 
    ///     phone/identifier match an account, an array of ForgotUsernameMasked 
    ///     objects is returned, which will contain a list of masked usernames 
    ///     and security question info.
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?, completion: @escaping (_ result: ServiceResult<[ForgotUsernameMasked]>) -> Void)
    
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
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String, completion: @escaping (_ result: ServiceResult<String>) -> Void)
    
    /// Look up an account number by phone and id
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin) - varies by opco.
    ///   - completion: the completion block to execute upon completion. If the
    ///     phone/id match an account, an array of AccountLookupResult objects
    ///     is returned.
    func lookupAccount(phone: String, identifier: String, completion: @escaping (_ result: ServiceResult<[AccountLookupResult]>) -> Void)
    
    /// Reset a password by providing your username
    ///
    /// - Parameters:
    ///   - username: the username associated with the account.
    ///   - completion: the completion block to execute upon completion
    ///     of the password reset initiation process
    func recoverPassword(username: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
}


// MARK: - Reactive Extension to AuthenticationService
extension AuthenticationService {
    
    /// Authenticate a user with the supplied credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    /// - Returns: An observable to subscribe to.
    func login(_ username: String, password: String, stayLoggedIn: Bool) -> Observable<ProfileStatus> {
        return Observable.create { observer in
            self.login(username, password: password, stayLoggedIn: stayLoggedIn, completion: { (result: ServiceResult<ProfileStatus>) in
                switch (result) {
                case ServiceResult.Success(let profStatus):
                    observer.onNext(profStatus)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func validateLogin(_ username: String, password: String) -> Observable<Void> {
        return Observable.create { observer in
            self.validateLogin(username, password: password, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success():
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
    
    /// Log out the currently logged in user
    ///
    /// Note that this operation can and should have the side effect of removing
    /// any cached information related to the user, either in memory or on disk.
    ///
    /// - Returns: An observable to subscribe to.
    func logout() -> Observable<Void> {
        return Observable.create { observer in
            self.logout(completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }) 
            
            return Disposables.create()
        }
    }
    
    /// Change the currently logged in users password.
    ///
    /// - Parameters:
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    /// - Returns: An observable to subscribe to.
    func changePassword(_ currentPassword: String, newPassword: String) -> Observable<Void> {
        return Observable.create { observer in
            self.changePassword(currentPassword, newPassword: newPassword, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
    
    /// Change the password of the given user
    ///
    /// - Parameters:
    ///   - username: user's username
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    /// - Returns: An observable to subscribe to.
    func changePasswordAnon(_ username: String, currentPassword: String, newPassword: String) -> Observable<Void> {
        return Observable.create { observer in
            self.changePasswordAnon(username, currentPassword: currentPassword, newPassword: newPassword, completion: { (result: ServiceResult<Void>) in
                switch(result){
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    
    func getMaintenanceMode() -> Observable<Maintenance> {
        return Observable.create { observer in
            self.getMaintenanceMode( completion: { (result: ServiceResult<Maintenance>) in
            switch(result){
            case ServiceResult.Success(let maintenanceInfo):
                observer.onNext(maintenanceInfo)
                observer.onCompleted()
            case ServiceResult.Failure(let err):
                observer.onError(err)
            }
        })
        return Disposables.create()
        }
    }
    
    /// Attempt to recover a username by providing a phone number and identifier.
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    /// - Returns: An observable to subscribe to.
    func recoverMaskedUsername(phone: String, identifier: String?, accountNumber: String?) -> Observable<[ForgotUsernameMasked]> {
        return Observable.create { observer in
            self.recoverMaskedUsername(phone: phone, identifier: identifier, accountNumber: accountNumber, completion: { (result: ServiceResult<[ForgotUsernameMasked]>) in
                switch (result) {
                case ServiceResult.Success(let usernameArray):
                    observer.onNext(usernameArray)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    /// Attempt to recover a username by providing a security question answer
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin/account#) - varies by opco.
    ///   - questionId: the question id
    ///   - questionResponse: the question response
    ///   - cipher: the cipher for the username
    /// - Returns: An observable to subscribe to.
    func recoverUsername(phone: String, identifier: String?, accountNumber: String?, questionId: Int, questionResponse: String, cipher: String) -> Observable<String> {
        return Observable.create { observer in
            self.recoverUsername(phone: phone, identifier: identifier, accountNumber: accountNumber, questionId: questionId, questionResponse: questionResponse, cipher: cipher, completion: { (result: ServiceResult<String>) in
                switch (result) {
                case ServiceResult.Success(let username):
                    observer.onNext(username)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    /// Look up an account number by phone and id
    ///
    /// - Parameters:
    ///   - phone: the phone number associated with the customer.
    ///   - identifier: the identifier (e.g ssn/pin) - varies by opco.
    /// - Returns: An observable to subscribe to.
    func lookupAccount(phone: String, identifier: String) -> Observable<[AccountLookupResult]> {
        return Observable.create { observer in
            self.lookupAccount(phone: phone, identifier: identifier, completion: { (result: ServiceResult<[AccountLookupResult]>) in
                switch (result) {
                case ServiceResult.Success(let accounts):
                    observer.onNext(accounts)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    /// Reset a password by providing your username
    ///
    /// - Parameters:
    ///   - username: the username associated with the account.
    /// - Returns: An observable to subscribe to.
    func recoverPassword(username: String) -> Observable<Void> {
        return Observable.create { observer in
            self.recoverPassword(username: username, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success():
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
}
