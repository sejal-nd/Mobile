//
//  EditCreditCardViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class EditCreditCardViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
        
    let expMonth = Variable("")
    let expYear = Variable("")
    let cvv = Variable("")
    let zipCode = Variable("")
    
    var oneTouchPayInitialValue = Variable(false)
    let oneTouchPay = Variable(false)
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    var walletItem: WalletItem! // Passed from WalletViewController
    var oneTouchPayItem: WalletItem!
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    private(set) lazy var saveButtonIsEnabled: Driver<Bool> = Driver.combineLatest(self.cardDataEntered,
                                                                                   self.oneTouchPayInitialValue.asDriver(),
                                                                                   self.oneTouchPay.asDriver())
    { $0 || ($1 != $2) }
    
    private(set) lazy var cardDataEntered: Driver<Bool> = Driver.combineLatest([self.expMonthIs2Digits,
                                                                                self.expMonthIsValidMonth,
                                                                                self.expYearIs4Digits,
                                                                                self.expYearIsNotInPast,
                                                                                self.cvvIsCorrectLength,
                                                                                self.zipCodeIs5Digits])
    { !$0.contains(false) }
    
    private(set) lazy var expMonthIs2Digits: Driver<Bool> = self.expMonth.asDriver().map { $0.count == 2 }
    
    private(set) lazy var expMonthIsValidMonth: Driver<Bool> = self.expMonth.asDriver().map {
            (1...12).map { String(format: "%02d", $0) }.contains($0)
        }
    
    private(set) lazy var expYearIs4Digits: Driver<Bool> = self.expYear.asDriver().map { $0.count == 4
        }
    
    private(set) lazy var expYearIsNotInPast: Driver<Bool> = self.expYear.asDriver().map {
        guard let enteredDate = DateFormatter.yyyyFormatter.date(from: $0) else { return false }
        let enteredYear = Calendar.opCo.component(.year, from: enteredDate)
        let todayYear = Calendar.opCo.component(.year, from: Date())
        
        return enteredYear >= todayYear
    }
    
    private(set) lazy var cvvIsCorrectLength: Driver<Bool> = self.cvv.asDriver().map { $0.count == 3 || $0.count == 4 }
    
    private(set) lazy var zipCodeIs5Digits: Driver<Bool> = self.zipCode.asDriver().map { $0.count == 5 }
    
    func editCreditCard(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        walletService.updateCreditCard(walletItemID: walletItem.walletItemID!, customerNumber: AccountsStore.shared.customerIdentifier, expirationMonth: expMonth.value, expirationYear: expYear.value, securityCode: cvv.value, postalCode: zipCode.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func deleteCreditCard(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
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
    
    var oneTouchDisplayString: String {
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
