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

    var currentAccountDetail: AccountDetail?
    
    required init(accountService: AccountService) {
        self.accountService = accountService
    }
    
    deinit {
        if let disposable = currentGetAccountDetailDisposable {
            disposable.dispose()
        }
    }
    
    func getAccountDetails(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        if let disposable = currentGetAccountDetailDisposable {
            disposable.dispose()
        }
        
        currentGetAccountDetailDisposable = accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { accountDetail in
                self.currentAccountDetail = accountDetail
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
    }
}
