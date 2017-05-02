//
//  BillViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BillViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    
    private var currentGetAccountDetailDisposable: Disposable?

    var currentAccount: Account?
    var currentAccountDetail: AccountDetail?
    
    required init(accountService: AccountService) {
        self.accountService = accountService
    }
    
    deinit {
        if let disposable = currentGetAccountDetailDisposable {
            disposable.dispose()
        }
    }
    
    func getAccounts(onSuccess: @escaping ([Account]) -> Void, onError: @escaping (String) -> Void) {
        accountService.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { accounts in
                self.currentAccount = accounts[0]
                onSuccess(accounts)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func getAccountDetails(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        if let disposable = currentGetAccountDetailDisposable {
            disposable.dispose()
        }
        
        currentGetAccountDetailDisposable = accountService.fetchAccountDetail(account: currentAccount!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { accountDetail in
//                print("------------------------------------------------")
//                print(accountDetail)
//                print("------------------------------------------------")
                self.currentAccountDetail = accountDetail
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
    }
}
