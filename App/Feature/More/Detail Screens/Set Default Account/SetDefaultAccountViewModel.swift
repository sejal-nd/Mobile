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
        
    var initialDefaultAccount: Account? = nil
    let selectedAccount = BehaviorRelay<Account?>(value: nil)

    let bag = DisposeBag()
    
    init() {
        if let currDefault = AccountsStore.shared.accounts.first(where: { $0.isDefault }) {
            initialDefaultAccount = currDefault
            selectedAccount.accept(currDefault)
        }
    }
    
    func setDefaultAccount(onSuccess: @escaping () -> Void,
                           onError: @escaping (String) -> Void) {
        AccountService.setDefaultAccount(accountNumber: selectedAccount.value?.accountNumber ?? "") { defaultAccountResult in
            switch defaultAccountResult {
            case .success:
                AccountService.fetchAccounts { accountsResult in
                    switch accountsResult {
                    case .success:
                        onSuccess()
                    case .failure(let error):
                        onError(error.description)
                    }
                }
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    private(set) lazy var saveButtonEnabled: Driver<Bool> =
        self.selectedAccount.asDriver().map { [weak self] in
            $0 != self?.initialDefaultAccount
        }
    
}
