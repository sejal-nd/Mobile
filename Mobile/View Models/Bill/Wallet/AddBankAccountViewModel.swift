//
//  AddBankAccountViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AddBankAccountViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    let addBankFormViewModel: AddBankFormViewModel!
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    var oneTouchPayItem: WalletItem!
    
    required init(walletService: WalletService, addBankFormViewModel: AddBankFormViewModel) {
        self.walletService = walletService
        self.addBankFormViewModel = addBankFormViewModel
    }
    
    private(set) lazy var saveButtonIsEnabled: Driver<Bool> = {
        if Environment.shared.opco == .bge {
            return Driver.combineLatest([self.addBankFormViewModel.accountHolderNameHasText,
                                         self.addBankFormViewModel.accountHolderNameIsValid,
                                         self.addBankFormViewModel.routingNumberIsValid,
                                         self.addBankFormViewModel.accountNumberHasText,
                                         self.addBankFormViewModel.accountNumberIsValid,
                                         self.addBankFormViewModel.confirmAccountNumberMatches.asDriver(),
                                         self.addBankFormViewModel.nicknameHasText,
                                         self.addBankFormViewModel.nicknameErrorString.asDriver().map{ $0 == nil }]) { !$0.contains(false) }
        } else {
            return Driver.combineLatest([self.addBankFormViewModel.routingNumberIsValid,
                                         self.addBankFormViewModel.accountNumberHasText,
                                         self.addBankFormViewModel.accountNumberIsValid,
                                         self.addBankFormViewModel.confirmAccountNumberMatches.asDriver(),
                                         self.addBankFormViewModel.nicknameErrorString.asDriver().map{ $0 == nil }]) { !$0.contains(false) }
        }
    }()
    
    func addBankAccount(onDuplicate: @escaping (String) -> Void, onSuccess: @escaping (WalletItemResult) -> Void, onError: @escaping (String) -> Void) {
        var accountType: String?
        if Environment.shared.opco == .bge {
            accountType = addBankFormViewModel.selectedSegmentIndex.value == 0 ? "checking" : "saving"
        }
        let accountName: String? = addBankFormViewModel.accountHolderName.value.isEmpty ? nil : addBankFormViewModel.accountHolderName.value
        let nickname: String? = addBankFormViewModel.nickname.value.isEmpty ? nil : addBankFormViewModel.nickname.value
        
        let bankAccount = BankAccount(bankAccountNumber: addBankFormViewModel.accountNumber.value,
                                      routingNumber: addBankFormViewModel.routingNumber.value,
                                      accountNickname: nickname,
                                      accountType: accountType,
                                      accountName: accountName,
                                      oneTimeUse: false)
        
        walletService
            .addBankAccount(bankAccount, forCustomerNumber: AccountsStore.shared.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItemResult in
                onSuccess(walletItemResult)
            }, onError: { (error: Error) in
                let serviceError = error as! ServiceError
                
                if serviceError.serviceCode == ServiceErrorCode.dupPaymentAccount.rawValue {
                    onDuplicate(error.localizedDescription)
                } else {
                    onError(error.localizedDescription)
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
