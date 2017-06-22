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
    private var billingHistory = Variable<BillingHistory>(<#Element#>)
    
    init(billService: BillService) {
        self.billService = billService
        
        let calendar = Calendar.current
        let lastYear = calendar.date(byAdding: .month, value: -12, to: Date())
        
        billService.fetchBillingHistory(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber, startDate: lastYear!, endDate: Date())
            .bind(to: billingHistory)
            .addDisposableTo(disposeBag)
    }
}
