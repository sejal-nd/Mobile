//
//  AccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

/// The AccountService protocol defines the interface necessary
/// to deal with fetching and updating accoutns associated with
/// the currently logged in customer.
protocol AccountService {

    
    /// Fetch a page of accounts for the current customer.
    ///
    /// - Parameters:
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain an AccountPage on success, or a ServiceError on failure.
    func fetchAccounts(completion: @escaping (_ result: ServiceResult<[Account]>) -> Void)
    
    
    /// Fetch an accounts detailed information.
    ///
    /// - Parameters:
    ///   - account: the account to fetch
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the AccountDetails on success, or a ServiceError on failure.
    func fetchAccountDetail(account: Account, completion: @escaping (_ result: ServiceResult<AccountDetail>) -> Void)
    
    
    /// Updates the Release of Information in preferences for the specified account (PECO ONLY)
    ///
    /// - Parameters:
    ///   - account: the account to update
    ///   - completion: the block to execute upon completion
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    
    /// Sets the user's default account to the specified account
    ///
    /// - Parameters:
    ///   - account: the account to set as default
    func setDefaultAccount(account: Account, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
}

// MARK: - Reactive Extension to AccountService
extension AccountService {
    
    func fetchAccounts() -> Observable<[Account]> {
        return Observable.create { observer in
            self.fetchAccounts { (result: ServiceResult<[Account]>) in
                switch result {
                case ServiceResult.Success(let accounts):
                    observer.onNext(accounts)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        return Observable.create { observer in
            self.fetchAccountDetail(account: account, completion: { (result: ServiceResult<AccountDetail>) in
                switch result {
                case ServiceResult.Success(let accountDetail):
                    observer.onNext(accountDetail)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int) -> Observable<Void> {
        return Observable.create { observer in
            self.updatePECOReleaseOfInfoPreference(account: account, selectedIndex: selectedIndex, completion: { (result: ServiceResult<Void>) in
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
    
    func setDefaultAccount(account: Account) -> Observable<Void> {
        return Observable.create { observer in
            self.setDefaultAccount(account: account, completion: { (result: ServiceResult<Void>) in
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

