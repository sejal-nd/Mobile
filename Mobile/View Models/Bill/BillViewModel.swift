//
//  BillViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class BillViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    
    private var currentGetAccountDetailDisposable: Disposable?

    let fetchAccountDetailSubject = PublishSubject<Void>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let isFetchingAccountDetail: Driver<Bool>
    
    required init(accountService: AccountService) {
        self.accountService = accountService
        
        
        let fetchingAccountDetailTracker = ActivityTracker()
        isFetchingAccountDetail = fetchingAccountDetailTracker.asDriver()
        
        fetchAccountDetailSubject
            .flatMapLatest {
                accountService
                    .fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                    .trackActivity(fetchingAccountDetailTracker)
                    .do(onError: {
                        dLog(message: $0.localizedDescription)
                    })
            }
            .bind(to: currentAccountDetail)
            .addDisposableTo(disposeBag)
    }
    
    func fetchAccountDetail() {
        fetchAccountDetailSubject.onNext()
    }
    
    var currentAccountDetailUnwrapped: Driver<AccountDetail> {
        return currentAccountDetail.asObservable()
            .unwrap()
            .asDriver(onErrorDriveWith: Driver.empty())
    }
    
    lazy var totalAmountText: Driver<String> = {
        return self.currentAccountDetailUnwrapped
            .map { $0.billingInfo.netDueAmount?.currencyString ?? "--" }
    }()
    
    lazy var shouldHidePaperless: Driver<Bool> = {
        return self.currentAccountDetailUnwrapped.map { !$0.isEBillEligible }
    }()
    
    lazy var shouldHideBudget: Driver<Bool> = {
        return self.currentAccountDetailUnwrapped.map {
            !$0.isBudgetBillEligible && Environment.sharedInstance.opco != .bge
        }
    }()
    
    lazy var paperlessButtonText: Driver<NSAttributedString> = {
        return self.currentAccountDetailUnwrapped.map { accountDetail in
            NSAttributedString(string: "enrolled")
        }
    }()
    
    lazy var budgetButtonText: Driver<NSAttributedString> = {
        return self.currentAccountDetailUnwrapped.map { accountDetail in
            NSAttributedString(string: "enrolled")
        }
    }()
    
}
