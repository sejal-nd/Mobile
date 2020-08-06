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
        
    let monthsBackward = StormModeStatus.shared.isOn ? -2 : -24
    let monthsForward = 12
    
    // Pass these in
    var accountDetail: AccountDetail!
    var billingHistory: BillingHistoryResult? // Passed in when viewing "More Activity", otherwise it's fetched here
    var viewingMoreActivity = false // Pass true to indicate "More Activity" screen

    init() {
    }
    
    func getBillingHistory(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        let now = Date.now
        let lastYear = Calendar.opCo.date(byAdding: .month, value: monthsBackward, to: now)!
        let theFuture = Calendar.opCo.date(byAdding: .month, value: monthsForward, to: now)!
                
        BillService.fetchBillingHistory(accountNumber: AccountsStore.shared.currentAccount.accountNumber, startDate: lastYear, endDate: theFuture) { [weak self] result in
            switch result {
            case .success(let billingHistory):
                self?.billingHistory = billingHistory
                success()
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    var shouldShowAutoPayCell: Bool {
        return !viewingMoreActivity && (accountDetail.isBGEasy || accountDetail.isAutoPay)
    }
    
    var shouldShowAutoPayCellDetailLabel: Bool {
        // Show the detail label when there is no upcoming AutoPay payment scheduled (BGE & PHI opcos only)
        return Environment.shared.opco == .bge || Environment.shared.opco.isPHI &&
            shouldShowAutoPayCell && !accountDetail.isBGEasy &&
            self.billingHistory?.upcoming.first(where: { $0.isAutoPayPayment }) == nil
    }

}
