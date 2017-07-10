//
//  DefaultAccountViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class DefaultAccountViewModel {
    
    let bag = DisposeBag()
    
    let accounts: Variable<[Account]>
    let accountService: AccountService
    
    let changeDefaultAccount = PublishSubject<Account>()
    let shouldShowLoadingIndicator: Driver<Bool>

    private let requestTracker = ActivityTracker()
    
    init(withAccounts accountsValue: [Account], accountService: AccountService) {
        accounts = Variable(accountsValue)
        self.accountService = accountService
        
        shouldShowLoadingIndicator = requestTracker.asDriver()
        
        changeDefaultAccountResult.elements()
            .bind(to: accounts)
            .addDisposableTo(bag)
    }
    
    private lazy var changeDefaultAccountResult: Observable<Event<[Account]>> = self.changeDefaultAccount
        .flatMapLatest(self.setDefaultAccount)
        .flatMapLatest(self.fetchAccounts)
        .materialize()
        .shareReplay(1)
    
    lazy var changeDefaultAccountErrorMessage: Driver<String> = self.changeDefaultAccountResult.errors()
        .map { $0.localizedDescription }
        .asDriver(onErrorJustReturn: "")
    
    private func setDefaultAccount(account: Account) -> Observable<Void> {
        return accountService.setDefaultAccount(account: account)
            .trackActivity(requestTracker)
    }
    
    private func fetchAccounts() -> Observable<[Account]> {
        return accountService.fetchAccounts()
            .trackActivity(requestTracker)
    }
    
}
