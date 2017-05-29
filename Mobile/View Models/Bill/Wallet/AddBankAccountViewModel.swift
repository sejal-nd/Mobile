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
    let confirmRoutingNumber = Variable("")
    let accountNumber = Variable("")
    let confirmAccountNumber = Variable("")
    let nickname = Variable("")
    let oneTouchPay = Variable(false)
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
            return Observable.combineLatest([accountHolderNameHasText(), routingNumberIsValid(), confirmRoutingNumberMatches(), accountNumberHasText(), accountNumberIsValid(), confirmAccountNumberMatches(), nicknameHasText(), nicknameIsValid()]) {
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
    
    func confirmRoutingNumberMatches() -> Observable<Bool> {
        return Observable.combineLatest(routingNumber.asObservable(), confirmRoutingNumber.asObservable()) {
            return $0 == $1
        }
    }
    
    func accountNumberHasText() -> Observable<Bool> {
        return accountNumber.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func accountNumberIsValid() -> Observable<Bool> {
        return accountNumber.asObservable().map {
            return $0.characters.count >= 8 && $0.characters.count <= 17
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
    
    func addBankAccount(onSuccess: @escaping (WalletItemResult) -> Void, onError: @escaping (String) -> Void) {
        var accountType: String?
        if Environment.sharedInstance.opco == .bge {
            accountType = selectedSegmentIndex.value == 0 ? "checking" : "saving"
        }
        let accountName: String? = self.accountHolderName.value.isEmpty ? nil : self.accountHolderName.value
        let nickname: String? = self.nickname.value.isEmpty ? nil : self.nickname.value
        
        let bankAccount = BankAccount(bankAccountNumber: accountNumber.value, routingNumber: routingNumber.value, accountNickname: nickname, accountType: accountType, accountName: accountName, oneTimeUse: false)
        walletService.addBankAccount(bankAccount, forCustomerNumber: accountDetail.customerInfo.number!).observeOn(MainScheduler.instance).subscribe(onNext: { walletItemResult in
            onSuccess(walletItemResult)
        }, onError: { err in
            onError(err.localizedDescription)
        }).addDisposableTo(disposeBag)
    }

}
