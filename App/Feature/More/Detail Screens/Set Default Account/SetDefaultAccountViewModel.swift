//
//  SetDefaultAccountViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SetDefaultAccountViewModel {
    
    let accountService: AccountService
    
    var initialDefaultAccount: Account? = nil
    let selectedAccount = BehaviorRelay<Account?>(value: nil)

    let bag = DisposeBag()
    
    init(accountService: AccountService) {
        self.accountService = accountService
        
        if let currDefault = AccountsStore.shared.accounts.first(where: { $0.isDefault }) {
            initialDefaultAccount = currDefault
            selectedAccount.accept(currDefault)
        }
    }
    
    func setDefaultAccount(onSuccess: @escaping () -> Void,
                           onError: @escaping (String) -> Void) {
        NewAccountService.rx.setDefaultAccount(accountNumber: selectedAccount.value!.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                NewAccountService.rx.fetchAccounts()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { __SRD in
                        onSuccess()
                    }, onError: { error in
                        onError(error.localizedDescription)
                    }).disposed(by: self.bag)
            }, onError: { error in
                onError(error.localizedDescription)
            }).disposed(by: bag)
    }
    
    private(set) lazy var saveButtonEnabled: Driver<Bool> =
        self.selectedAccount.asDriver().map { [weak self] in
            $0 != self?.initialDefaultAccount
        }
    
}
