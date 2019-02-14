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
    var oneTouchPayItem: WalletItem!
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        return Observable.combineLatest(oneTouchPayInitialValue.asObservable(), oneTouchPay.asObservable()) {
            return $0 != $1
        }
    }

    func deleteBankAccount(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        walletService.deletePaymentMethod(walletItem: walletItem)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func enableOneTouchPay(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        walletService.setOneTouchPayItem(walletItemId: walletItem.walletItemID!,
                                         walletId: walletItem.walletExternalID,
                                         customerId: AccountsStore.shared.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func deleteOneTouchPay(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        walletService.removeOneTouchPayItem(customerId: AccountsStore.shared.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func getOneTouchDisplayString() -> String {
        if let item = oneTouchPayItem {
            switch item.bankOrCard {
            case .bank:
                return String(format: NSLocalizedString("You are currently using bank account %@ as your default payment method.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
            case .card:
                return String(format: NSLocalizedString("You are currently using card %@ as your default payment method.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
            }
        }
        return NSLocalizedString("Set this payment method as default to easily pay from the Home and Bill screens.", comment: "")
    }
}
