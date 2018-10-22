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
        let now = Date()
        let lastYear = Calendar.opCo.date(byAdding: .month, value: months, to: now)!
        let theFuture = Calendar.opCo.date(byAdding: .year, value: 5, to: now)!
        billService.fetchBillingHistory(accountNumber: AccountsStore.shared.currentAccount.accountNumber, startDate: lastYear, endDate: theFuture)
            .subscribe(onNext: { billingHistory in
                success(billingHistory)
            }, onError: { error in
                failure(error)
            })
            .disposed(by: disposeBag)
    }
}
