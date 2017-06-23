//
//  BillingHistoryViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BillingHistoryViewModel {

    let disposeBag = DisposeBag()
    
    private var billService: BillService
    
    init(billService: BillService) {
        self.billService = billService
    }
    
    func getBillingHistory(success: @escaping (BillingHistory) -> Void, failure: @escaping (Error) -> Void) {
        let calendar = Calendar.current
        let lastYear = calendar.date(byAdding: .month, value: -24, to: Date())
        billService.fetchBillingHistory(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber, startDate: lastYear!, endDate: Date())
            .subscribe(onNext: { billingHistory in
                success(billingHistory)
            }, onError: { error in
                failure(error)
            })
            .addDisposableTo(disposeBag)
    }
}
