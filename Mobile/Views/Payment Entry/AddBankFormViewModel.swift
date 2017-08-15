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
// Default account toggle

class AddBankFormViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
    // Normal Add Bank forms
    let selectedSegmentIndex = Variable(0)
    let accountHolderName = Variable("")
    let routingNumber = Variable("")
    let accountNumber = Variable("")
    let confirmAccountNumber = Variable("")
    let nickname = Variable("")
    let oneTouchPay = Variable(false)

    // Payment workflow
    let paymentWorkflow = Variable(false) // If form is being used on payment screen
    let saveToWallet = Variable(true) // Switch value
    
    var bankName = "";
    var nicknamesInWallet = [String]()

    required init(walletService: WalletService) {
        self.walletService = walletService
        
        // When Save To Wallet switch is toggled off, reset the fields that get hidden
        saveToWallet.asObservable().subscribe(onNext: { save in
            if !save {
                self.nickname.value = ""
                self.oneTouchPay.value = false
            }
        }).disposed(by: disposeBag)
    }
    
    func accountHolderNameHasText() -> Observable<Bool> {
        return accountHolderName.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func accountHolderNameIsValid() -> Observable<Bool> {
        return accountHolderName.asObservable().map {
            return $0.characters.count >= 3
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
    
    func nicknameErrorString() -> Observable<String?> {
        return nickname.asObservable().map {
            // If BGE, check if at least 3 characters
            if Environment.sharedInstance.opco == .bge && !$0.isEmpty && $0.characters.count < 3 {
                return NSLocalizedString("Must be at least 3 characters", comment: "")
            }
            
            // Check for special characters
            var trimString = $0.components(separatedBy: CharacterSet.whitespaces).joined(separator: "")
            trimString = trimString.components(separatedBy: CharacterSet.alphanumerics).joined(separator: "")
            if !trimString.isEmpty {
                return NSLocalizedString("Can only contain letters, numbers, and spaces", comment: "")
            }
            
            // Check for duplicate nickname
            if self.nicknamesInWallet.map({ nickname in
                return nickname.lowercased()
            }).contains($0.lowercased()) {
                return NSLocalizedString("This nickname is already in use", comment: "")
            }
            
            return nil
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
            }).disposed(by: disposeBag)
    }

    
}
