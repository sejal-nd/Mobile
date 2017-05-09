//
//  BillViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BillViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    
    private var currentGetAccountDetailDisposable: Disposable?

    let fetchAccountDetailSubject = PublishSubject<Void>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let fetchingAccountDetail: Driver<Bool>
    
    required init(accountService: AccountService) {
        self.accountService = accountService
        
        
        let fetchingAccountDetailTracker = ActivityTracker()
        fetchingAccountDetail = fetchingAccountDetailTracker.asDriver()
        
        fetchAccountDetailSubject
            .flatMapLatest {
                accountService
                    .fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                    .trackActivity(fetchingAccountDetailTracker)
                    .do(onError: {
                        dLog(message: $0.localizedDescription)
                    })
            }
            .bindTo(currentAccountDetail)
            .addDisposableTo(disposeBag)
    }
    
    func fetchAccountDetail() {
        fetchAccountDetailSubject.onNext()
    }
    
}
