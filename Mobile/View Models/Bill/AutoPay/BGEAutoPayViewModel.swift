//
//  BGEAutoPayViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BGEAutoPayViewModel {
    
    let disposeBag = DisposeBag()
    
    private var paymentService: PaymentService

    required init(paymentService: PaymentService) {
        self.paymentService = paymentService
    }
    
    func getAutoPayInfo(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { billingInfo in
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    
}
