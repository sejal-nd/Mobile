//
//  BillingHistoryViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BillingHistoryViewModel {
    
    let monthsBackward = StormModeStatus.shared.isOn ? -2 : -24
    let monthsforward = 12

    let disposeBag = DisposeBag()
    
    private var billService: BillService
    
    init(billService: BillService) {
        self.billService = billService
    }
    
    func getBillingHistory(success: @escaping (BillingHistory) -> Void, failure: @escaping (Error) -> Void) {
        let now = Date.now
        let lastYear = Calendar.opCo.date(byAdding: .month, value: monthsBackward, to: now)!
        let theFuture = Calendar.opCo.date(byAdding: .month, value: monthsforward, to: now)!
        billService.fetchBillingHistory(accountNumber: AccountsStore.shared.currentAccount.accountNumber, startDate: lastYear, endDate: theFuture)
            .subscribe(onNext: { billingHistory in
                success(billingHistory)
            }, onError: { error in
                failure(error)
            })
            .disposed(by: disposeBag)
    }
}
