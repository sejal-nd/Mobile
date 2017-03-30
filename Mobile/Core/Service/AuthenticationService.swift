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
    ///     The ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func login(_ username: String, password: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void)
    
    /// Log out the currently logged in user
    ///
    /// Note that this operation can and should have the side effect of removing
    /// any cached information related to the user, either in memory or on disk.
    ///
    /// - Parameter completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will econtain the user id on success,
    ///     or the error on failure.
    func logout(completion: @escaping (_ result: ServiceResult<Void>) -> Swift.Void)
    
    /// Change the currently logged in users password.
    ///
    /// - Parameters:
    ///   - currentPassword: the users current password.
    ///   - newPassword: the users new password to set.
    ///   - completion: the completion block to execute upon completion. The
    ///     ServiceResult that is provided will contain the user id on success,
    ///     or the error on failure.
    func changePassword(_ currentPassword: String, newPassword: String, completion: @escaping (_ result: ServiceResult<Void>) -> Swift.Void)
}


// MARK: - Reactive Extension to AuthenticationService
extension AuthenticationService {
    
    /// Authenticate a user with the supplied credentials.
    ///
    /// - Parameters:
    ///   - username: the username to authenticate with.
    ///   - password: the password to authenticate with.
    /// - Returns: An observable to subscribe to.
    func login(_ username: String, password: String) -> Observable<Bool> {
        return Observable.create { observer in
            self.login(username, password: password, completion: { (result: ServiceResult<String>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext(true)
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
    func logout() -> Observable<Bool> {
        return Observable.create { observer in
            self.logout(completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext(true)
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
    func changePassword(_ currentPassword: String, newPassword: String) -> Observable<Bool> {
        return Observable.create { observer in
            self.changePassword(currentPassword, newPassword: newPassword, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext(true)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
}
