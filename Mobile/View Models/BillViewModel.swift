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

    var currentAccount: Account?
    
    required init(accountService: AccountService) {
        self.accountService = accountService
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
}
