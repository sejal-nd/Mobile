//
//  PaperlessEBillViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class PaperlessEBillViewModel {
    let bag = DisposeBag()
    
    let accounts = Variable<[Account]>([])
    let accountsToEnroll = Variable(Set<Account>())
    let enrollAllAccounts = Variable<Bool>(true)
    
    init() {
        Observable.combineLatest(accounts.asObservable(), accountsToEnroll.asObservable().map(Array.init))
        { accounts, accountsToEnroll in
            accounts.count == accountsToEnroll.count
        }
        .bindTo(enrollAllAccounts)
        .addDisposableTo(bag)
    }
}
