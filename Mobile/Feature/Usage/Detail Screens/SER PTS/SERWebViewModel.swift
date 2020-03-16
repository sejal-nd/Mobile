//
//  SERWebViewModel.swift
//  BGE
//
//  Created by Cody Dillon on 3/16/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SERWebViewModel {
    let disposeBag = DisposeBag()
    
    let accountDetail: AccountDetail
    let accountService: AccountService
    
    required init(accountService: AccountService, accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
        self.accountService = accountService
    }
}
