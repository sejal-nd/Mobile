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
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    
    let selectedSegmentIndex = Variable(0)
    let accountHolderName = Variable("")
    let routingNumber = Variable("")
    let accountNumber = Variable("")
    let confirmAccountNumber = Variable("")
    let nickname = Variable("")
    let oneTouchPay = Variable(false)
    
    var bankName = "";
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
            return Observable.combineLatest([accountHolderNameHasText(), routingNumberIsValid(), accountNumberHasText(), accountNumberIsValid(), confirmAccountNumberMatches(), nicknameHasText(), nicknameIsValid()]) {
                return !$0.contains(false)
            }
        } else {
            return Observable.combineLatest([routingNumberIsValid(), accountNumberHasText(), accountNumberIsValid(), confirmAccountNumberMatches(), nicknameIsValid()]) {
                return !$0.contains(false)
            }
        }
    }
    
    func accountHolderNameHasText() -> Observable<Bool> {
        return accountHolderName.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func routingNumberIsValid() -> Observable<Bool> {
        return routingNumber.asObservable().map {
            return $0.characters.count == 9
        }
    }
    
    func accountNumberHasText() -> Observable<Bool> {
        return accountNumber.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func accountNumberIsValid() -> Observable<Bool> {
        return accountNumber.asObservable().map {
            return $0.characters.count >= 4 && $0.characters.count <= 17
        }
    }
    
    func confirmAccountNumberMatches() -> Observable<Bool> {
        return Observable.combineLatest(accountNumber.asObservable(), confirmAccountNumber.asObservable()) {
            return $0 == $1
        }
    }
    
    lazy var confirmRoutingNumberIsEnabled: Driver<Bool> = self.routingNumber.asDriver().map {
        return !$0.isEmpty
    }
    
    lazy var confirmAccountNumberIsEnabled: Driver<Bool> = self.accountNumber.asDriver().map {
        return !$0.isEmpty
    }
    
    func nicknameHasText() -> Observable<Bool> {
        return nickname.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func nicknameIsValid() -> Observable<Bool> {
        return nickname.asObservable().map {
            var trimString = $0.components(separatedBy: CharacterSet.whitespaces).joined(separator: "")
            trimString = trimString.components(separatedBy: CharacterSet.alphanumerics).joined(separator: "")
            return trimString.isEmpty
        }
    }
    
    func getBankName(onSuccess: @escaping () -> Void, onError: @escaping () -> Void) {
        walletService.fetchBankName(routingNumber.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { bankName in
                self.bankName = bankName
                onSuccess()
            }, onError: { (error: Error) in
                onError()
            }).addDisposableTo(disposeBag)
    }
    
    func addBankAccount(onSuccess: @escaping (WalletItemResult) -> Void, onError: @escaping (FiservError) -> Void) {
        var accountType: String?
        if Environment.sharedInstance.opco == .bge {
            accountType = selectedSegmentIndex.value == 0 ? "checking" : "saving"
        }
        let accountName: String? = self.accountHolderName.value.isEmpty ? nil : self.accountHolderName.value
        let nickname: String? = self.nickname.value.isEmpty ? nil : self.nickname.value
        
        let bankAccount = BankAccount(bankAccountNumber: accountNumber.value, routingNumber: routingNumber.value, accountNickname: nickname, accountType: accountType, accountName: accountName, oneTimeUse: false)
        
        walletService
            .addBankAccount(bankAccount, forCustomerNumber: accountDetail.customerInfo.number!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItemResult in
                onSuccess(walletItemResult)
            }, onError: { (err: Error) in
                onError(FiservErrorMapper.sharedInstance.getError(message: err.localizedDescription, context: "wallet"))
            })
            .addDisposableTo(disposeBag)
    }

}
