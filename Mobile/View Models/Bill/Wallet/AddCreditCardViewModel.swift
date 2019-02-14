//
//  AddCreditCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 5/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AddCreditCardViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    let addCardFormViewModel: AddCardFormViewModel!
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    var oneTouchPayItem: WalletItem!
    
    required init(walletService: WalletService, addCardFormViewModel: AddCardFormViewModel) {
        self.walletService = walletService
        self.addCardFormViewModel = addCardFormViewModel
    }
    
    private(set) lazy var saveButtonIsEnabled: Driver<Bool> = {
        if Environment.shared.opco == .bge {
            return Driver.combineLatest([self.addCardFormViewModel.nameOnCardHasText,
                                         self.addCardFormViewModel.cardNumberHasText,
                                         self.addCardFormViewModel.cardNumberIsValid,
                                         self.addCardFormViewModel.expMonthIs2Digits,
                                         self.addCardFormViewModel.expMonthIsValidMonth,
                                         self.addCardFormViewModel.expYearIs4Digits,
                                         self.addCardFormViewModel.expYearIsNotInPast,
                                         self.addCardFormViewModel.cvvIsCorrectLength,
                                         self.addCardFormViewModel.zipCodeIs5Digits,
                                         self.addCardFormViewModel.nicknameHasText,
                                         self.addCardFormViewModel.nicknameErrorString.map{ $0 == nil }]) {
                                            !$0.contains(false)
            }
        } else {
            return Driver.combineLatest([self.addCardFormViewModel.cardNumberHasText,
                                         self.addCardFormViewModel.cardNumberIsValid,
                                         self.addCardFormViewModel.expMonthIs2Digits,
                                         self.addCardFormViewModel.expMonthIsValidMonth,
                                         self.addCardFormViewModel.expYearIs4Digits,
                                         self.addCardFormViewModel.expYearIsNotInPast,
                                         self.addCardFormViewModel.cvvIsCorrectLength,
                                         self.addCardFormViewModel.zipCodeIs5Digits,
                                         self.addCardFormViewModel.nicknameErrorString.map{ $0 == nil }]) {
                                            !$0.contains(false)
            }
        }
    }()
    
    func addCreditCard(onDuplicate: @escaping (String) -> Void, onSuccess: @escaping (WalletItemResult) -> Void, onError: @escaping (String) -> Void) {
        
        let card = CreditCard(cardNumber: addCardFormViewModel.cardNumber.value, securityCode: addCardFormViewModel.cvv.value, cardHolderName: addCardFormViewModel.nameOnCard.value, expirationMonth: addCardFormViewModel.expMonth.value, expirationYear: addCardFormViewModel.expYear.value, postalCode: addCardFormViewModel.zipCode.value, nickname: addCardFormViewModel.nickname.value)
        
        walletService
            .addCreditCard(card, forCustomerNumber: AccountsStore.shared.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItemResult in
                onSuccess(walletItemResult)
            }, onError: { err in
                let serviceError = err as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.dupPaymentAccount.rawValue {
                    onDuplicate(err.localizedDescription)
                } else {
                    onError(err.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func enableOneTouchPay(walletItemID: String, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        walletService.setOneTouchPayItem(walletItemId: walletItemID,
                                         walletId: nil,
                                         customerId: AccountsStore.shared.customerIdentifier)
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
