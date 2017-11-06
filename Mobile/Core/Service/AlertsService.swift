//
//  AlertsService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol AlertsService {
    /// Fetch infomation about what push notifications the user is subscribed for
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain an AlertPreferences
    ////    object upon success, or the error on failure.
    func fetchAlertPreferences(accountNumber: String, completion: @escaping (_ result: ServiceResult<AlertPreferences>) -> Void)
    
    /// Fetch alerts language setting for ComEd account
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain either 'English' or 'Spanish'
    func fetchAlertLanguage(accountNumber: String, completion: @escaping (_ result: ServiceResult<String>) -> Void)
}

// MARK: - Reactive Extension to AlertsService
extension AlertsService {
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
}
