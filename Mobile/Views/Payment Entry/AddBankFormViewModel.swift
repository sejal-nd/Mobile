//
//  AddBankFormViewViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

// Checking/Savings Segmented Control (BGE ONLY)
// Bank account holder name (BGE ONLY)
// Routing Number with question mark
// Account number with question mark
// Confirm account number
// Nickname (Optional for ComEd/PECO, required for BGE)
// One touch pay toggle

class AddBankFormViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
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

    
}
