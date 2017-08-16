//
//  BillingHistoryViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BillingHistoryViewModel {
    
    let months = -24

    let disposeBag = DisposeBag()
    
    private var billService: BillService
    
    init(billService: BillService) {
        self.billService = billService
    }
    
    func getBillingHistory(success: @escaping (BillingHistory) -> Void, failure: @escaping (Error) -> Void) {
        let calendar = Calendar.current
        let lastYear = calendar.date(byAdding: .month, value: months, to: Date())
        let theFuture = Date().addingTimeInterval(TimeInterval(157700000))
        billService.fetchBillingHistory(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber, startDate: lastYear!, endDate: theFuture)
            .subscribe(onNext: { billingHistory in
                success(billingHistory)
            }, onError: { error in
                failure(error)
            })
            .disposed(by: disposeBag)
    }
}
