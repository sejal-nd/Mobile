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
        
        accountsResult.elements()
            .bind(to: accounts)
            .disposed(by: bag)
    }
    
    private lazy var changeDefaultAccountResult: Observable<Event<Void>> = self.changeDefaultAccount
        .flatMapLatest { [unowned self] in
            self.accountService.setDefaultAccount(account: $0)
                .trackActivity(self.requestTracker)
                .materialize()
        }
        .share()
        
    private lazy var accountsResult: Observable<Event<[Account]>> = self.changeDefaultAccountResult.elements()
        .flatMapLatest { [unowned self] _ in
            self.accountService.fetchAccounts()
                .trackActivity(self.requestTracker)
                .materialize()
        }
        .share()
    
    private(set) lazy var changeDefaultAccountErrorMessage: Driver<String> = Observable.merge(self.changeDefaultAccountResult.errors(),
                                                                                              self.accountsResult.errors())
        .map { $0.localizedDescription }
        .asDriver(onErrorJustReturn: "")
    
}
