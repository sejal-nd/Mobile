//
//  AuthenticatedService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension NewAccountService: ReactiveCompatible {}

extension Reactive where Base == NewAccountService {
    
    static func fetchAccounts() -> Observable<[Account]> {
        return Observable.create { observer -> Disposable in
            NewAccountService.fetchAccounts { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchAccountDetails(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                                    payments: Bool = true,
                                    programs: Bool = true,
                                    budgetBilling: Bool = true,
                                    alertPreferenceEligibilities: Bool = false) -> Observable<AccountDetail> {
        return Observable.create { observer -> Disposable in
            NewAccountService.fetchAccountDetails(accountNumber: accountNumber, payments: payments, programs: programs, budgetBilling: budgetBilling, alertPreferenceEligibilities: alertPreferenceEligibilities) { observer.handle(result: $0) }
            
            return Disposables.create()
        }
    }
    
    #if os(iOS)
    static func updatePECOReleaseOfInfoPreference(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber, selectedIndex: Int) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            NewAccountService.updatePECOReleaseOfInfoPreference(accountNumber: accountNumber, selectedIndex: selectedIndex) { result in
                switch result {
                case .success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    static func setDefaultAccount(accountNumber: String) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            NewAccountService.setDefaultAccount(accountNumber: accountNumber) { result in
                switch result {
                case .success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    static func setAccountNickname(nickname: String, accountNumber: String) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            NewAccountService.setAccountNickname(nickname: nickname, accountNumber: accountNumber) { result in
                switch result {
                case .success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    #endif
}

extension AnyObserver where Element: Decodable {
    func handle <T: Decodable>(result: Result<T, NetworkingError>) {
        switch result {
        case .success(let data):
            self.onNext(data as! Element)
            self.onCompleted()
        case .failure(let error):
            self.onError(error)
        }
    }
}
