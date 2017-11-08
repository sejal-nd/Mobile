//
//  AlertsService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol AlertsService {
    /// Register the device for push notifications
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain an AlertPreferences
    ////    object upon success, or the error on failure.
    func register(token: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Fetch infomation about what push notifications the user is subscribed for
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain an AlertPreferences
    ////    object upon success, or the error on failure.
    func fetchAlertPreferences(accountNumber: String, completion: @escaping (_ result: ServiceResult<AlertPreferences>) -> Void)
    
    /// Subscribes or unsubscribes from certain push notifications
    ///
    /// - Parameters:
    ///   - accountNumber: The account to set prefs for
    ///   - alertPreferences: An AlertPreferences object describing the alerts the user wants/does not want
    ///   - completion: the completion block to execute upon completion.
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Fetch alerts language setting for ComEd account
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain either 'English' or 'Spanish'
    func fetchAlertLanguage(accountNumber: String, completion: @escaping (_ result: ServiceResult<String>) -> Void)
    
    /// Set alerts language setting for ComEd account
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - english: true for "English", false for "Spanish"
    ///   - completion: the completion block to execute upon completion.
    func setAlertLanguage(accountNumber: String, english: Bool, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
}

// MARK: - Reactive Extension to AlertsService
extension AlertsService {
    func register(token: String) -> Observable<Void> {
        return Observable.create { observer in
            self.register(token: token, completion: { (result: ServiceResult<Void>) in
                switch result {
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
    
    func fetchAlertPreferences(accountNumber: String) -> Observable<AlertPreferences> {
        return Observable.create { observer in
            self.fetchAlertPreferences(accountNumber: accountNumber, completion: { (result: ServiceResult<AlertPreferences>) in
                switch result {
                case ServiceResult.Success(let alertPrefs):
                    observer.onNext(alertPrefs)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences) -> Observable<Void> {
        return Observable.create { observer in
            self.setAlertPreferences(accountNumber: accountNumber, alertPreferences: alertPreferences, completion: { (result: ServiceResult<Void>) in
                switch result {
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
    
    func fetchAlertLanguage(accountNumber: String) -> Observable<String> {
        return Observable.create { observer in
            self.fetchAlertLanguage(accountNumber: accountNumber, completion: { (result: ServiceResult<String>) in
                switch result {
                case ServiceResult.Success(let language):
                    observer.onNext(language)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func setAlertLanguage(accountNumber: String, english: Bool) -> Observable<Void> {
        return Observable.create { observer in
            self.setAlertLanguage(accountNumber: accountNumber, english: english, completion: { (result: ServiceResult<Void>) in
                switch result {
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
}
