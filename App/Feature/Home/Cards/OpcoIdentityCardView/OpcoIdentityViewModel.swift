//
//  OpcoIdentityViewModel.swift
//  BGE
//
//  Created by Majumdar, Amit on 22/07/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import RxCocoa
import RxSwift

class OpcoIdentityViewModel {
    
    private let accountService: AccountService
    var accountNickName = BehaviorRelay(value: "")

    required init(accountService: AccountService) {
        self.accountService = accountService
        
        if AccountsStore.shared.accounts != nil && !AccountsStore.shared.accounts.isEmpty {
            if let account = AccountsStore.shared.accounts.first,
                let nickname = account.accountNickname {
                accountNickName.accept(nickname)
            }
        }
    }
    
    var icon: UIImage? {
        return nil
    }

}
