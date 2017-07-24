//
//  BillingHistoryDetailsViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxSwiftExt

class BillingHistoryDetailsViewModel {
    let disposeBag = DisposeBag()
    
    private let paymentService: PaymentService
    
    private let billingHistory: BillingHistoryItem
    private lazy var paymentDetail: Observable<PaymentDetail> = Observable.just(self.billingHistory)
        .map { $0.paymentId }
        .unwrap()
        .flatMap(self.fetchPaymentDetails)
    
    required init(paymentService: PaymentService, billingHistoryItem: BillingHistoryItem) {
        self.paymentService = paymentService
        self.billingHistory = billingHistoryItem
    }
    
    func fetchPaymentDetails(paymentId: String) -> Observable<PaymentDetail> {
        return paymentService.fetchPaymentDetails(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber, paymentId: paymentId)
    }
}
