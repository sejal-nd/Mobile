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
    
    var bankName = ""
    var nicknamesInWallet = [String]()

    required init(walletService: WalletService) {
        self.walletService = walletService
        
        // When Save To Wallet switch is toggled off, reset the fields that get hidden
        saveToWallet.asObservable().filter(!).map { _ in "" }.bind(to: nickname).disposed(by: disposeBag)
        saveToWallet.asObservable().filter(!).map { _ in false }.bind(to: oneTouchPay).disposed(by: disposeBag)
    }
    
    private(set) lazy var accountHolderNameHasText: Driver<Bool> = self.accountHolderName.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var accountHolderNameIsValid: Driver<Bool> = self.accountHolderName.asDriver().map { $0.count >= 3 }
    
    private(set) lazy var routingNumberIsValid: Driver<Bool> = self.routingNumber.asDriver().map { $0.count == 9 }
    
    private(set) lazy var accountNumberHasText: Driver<Bool> = self.accountNumber.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var accountNumberIsValid: Driver<Bool> = self.accountNumber.asDriver().map { 4...17 ~= $0.count }
    
    private(set) lazy var confirmAccountNumberMatches: Driver<Bool> = Driver.combineLatest(self.accountNumber.asDriver(),
                                                                                           self.confirmAccountNumber.asDriver(),
                                                                                           resultSelector: ==)
    
    private(set) lazy var confirmRoutingNumberIsEnabled: Driver<Bool> = self.routingNumber.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var confirmAccountNumberIsEnabled: Driver<Bool> = self.accountNumber.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var nicknameHasText: Driver<Bool> = self.nickname.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var nicknameErrorString: Driver<String?> = self.nickname.asDriver().map { [weak self] in
        // If BGE, check if at least 3 characters
        if Environment.shared.opco == .bge && !$0.isEmpty && $0.count < 3 {
            return NSLocalizedString("Must be at least 3 characters", comment: "")
        }
        
        // Check for special characters
        var trimString = $0.components(separatedBy: CharacterSet.whitespaces).joined(separator: "")
        trimString = trimString.components(separatedBy: CharacterSet.alphanumerics).joined(separator: "")
        if !trimString.isEmpty {
            return NSLocalizedString("Can only contain letters, numbers, and spaces", comment: "")
        }
        
        // Check for duplicate nickname
        guard let self = self else { return nil }
        let isDuplicate = self.nicknamesInWallet.map { $0.lowercased() }.contains($0.lowercased())
        if isDuplicate {
            return NSLocalizedString("This nickname is already in use", comment: "")
        }
        
        return nil
    }
    
    func getBankName(onSuccess: @escaping () -> Void, onError: @escaping () -> Void) {
        walletService.fetchBankName(routingNumber: routingNumber.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] bankName in
                self?.bankName = bankName
                onSuccess()
            }, onError: { (error: Error) in
                onError()
            }).disposed(by: disposeBag)
    }
}
