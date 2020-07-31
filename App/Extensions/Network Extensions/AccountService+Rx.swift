//
//  AuthenticatedService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 7/8/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension AccountService: ReactiveCompatible {}

extension Reactive where Base == AccountService {
    
    static func fetchAccounts() -> Observable<[Account]> {
        return Observable.create { observer -> Disposable in
            AccountService.fetchAccounts { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchAccountDetails(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber,
                                    payments: Bool = true,
                                    programs: Bool = true,
                                    budgetBilling: Bool = true,
                                    alertPreferenceEligibilities: Bool = false) -> Observable<AccountDetail> {
        return Observable.create { observer -> Disposable in
            AccountService.fetchAccountDetails(accountNumber: accountNumber, payments: payments, programs: programs, budgetBilling: budgetBilling, alertPreferenceEligibilities: alertPreferenceEligibilities) { observer.handle(result: $0) }
            
            return Disposables.create()
        }
    }
    
    #if os(iOS)
    static func updatePECOReleaseOfInfoPreference(accountNumber: String = AccountsStore.shared.currentAccount.accountNumber, selectedIndex: Int) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            AccountService.updatePECOReleaseOfInfoPreference(accountNumber: accountNumber, selectedIndex: selectedIndex) { result in
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
            AccountService.setDefaultAccount(accountNumber: accountNumber) { result in
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
            AccountService.setAccountNickname(nickname: nickname, accountNumber: accountNumber) { result in
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
    
    static func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSODataResponse> {
        return Observable.create { observer -> Disposable in
            AccountService.fetchSSOData(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchFirstFuelSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSODataResponse> {
        return Observable.create { observer -> Disposable in
            AccountService.fetchFirstFuelSSOData(accountNumber: accountNumber, premiseNumber: premiseNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func fetchScheduledPayments(accountNumber: String) -> Observable<[PaymentItem]> {
        return Observable.create { observer -> Disposable in
            AccountService.fetchScheduledPayments(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }.catchErrorJustReturn([]) // TODO: This should be replaced with original logic once API is fixed
    }
    
    static func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        return Observable.create { observer -> Disposable in
            AccountService.fetchSERResults(accountNumber: accountNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
}
