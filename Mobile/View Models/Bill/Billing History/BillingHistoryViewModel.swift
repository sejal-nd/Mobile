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
    
    let monthsBackward = StormModeStatus.shared.isOn ? -2 : -24
    let monthsForward = 12
    
    // Pass these in
    var accountDetail: AccountDetail!
    var billingHistory: BillingHistory? // Passed in when viewing "More Activity", otherwise it's fetched here
    var viewingMoreActivity = false // Pass true to indicate "More Activity" screen

    init(billService: BillService) {
        self.billService = billService
    }
    
    func getBillingHistory(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let now = Date.now
        let lastYear = Calendar.opCo.date(byAdding: .month, value: monthsBackward, to: now)!
        let theFuture = Calendar.opCo.date(byAdding: .month, value: monthsForward, to: now)!
        billService.fetchBillingHistory(accountNumber: AccountsStore.shared.currentAccount.accountNumber, startDate: lastYear, endDate: theFuture)
            .subscribe(onNext: { [weak self] billingHistory in
                self?.billingHistory = billingHistory
                success()
            }, onError: { error in
                failure(error)
            })
            .disposed(by: disposeBag)
    }
    
    var shouldShowAutoPayCell: Bool {
        return !viewingMoreActivity && (accountDetail.isBGEasy || accountDetail.isAutoPay)
    }
}
