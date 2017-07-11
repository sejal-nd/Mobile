//
//  EditBankAccountViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class EditBankAccountViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
    var oneTouchPayInitialValue = Variable(false)
    var oneTouchPay = Variable(false)
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    var walletItem: WalletItem! // Passed from WalletViewController
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        return Observable.combineLatest(oneTouchPayInitialValue.asObservable(), oneTouchPay.asObservable()) {
            return $0 != $1
        }
    }

    func deleteBankAccount(onSuccess: @escaping () -> Void, onError: @escaping (FiservError) -> Void) {
        walletService.deletePaymentMethod(walletItem)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(FiservErrorMapper.sharedInstance.getError(message: err.localizedDescription, context: "wallet"));
            })
            .addDisposableTo(disposeBag)
    }
}
