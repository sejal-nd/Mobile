//
//  AddCardFormViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

// Name on card* (BGE only) - autopopulated with user's customer name
// Card number with camera icon*
// Expiration month* / Expiration year*
// CVV* / Zip*
// Nickname (optional)
// Default payment method

class AddCardFormViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
    // Normal Add Bank forms
    let nameOnCard = Variable("")
    let cardNumber = Variable("")
    let expMonth = Variable("")
    let expYear = Variable("")
    let cvv = Variable("")
    let zipCode = Variable("")
    let nickname = Variable("")
    let oneTouchPay = Variable(false)
    
    // Payment workflow
    let paymentWorkflow = Variable(false) // If form is being used on payment screen
    let saveToWallet = Variable(true) // Switch value
    
    var nicknamesInWallet = [String]()
    
    required init(walletService: WalletService) {
        self.walletService = walletService
        
        // When Save To Wallet switch is toggled off, reset the fields that get hidden
        saveToWallet.asObservable().filter(!).map { _ in "" }.bind(to: nickname).disposed(by: disposeBag)
        saveToWallet.asObservable().filter(!).map { _ in false }.bind(to: oneTouchPay).disposed(by: disposeBag)
    }
    
    private(set) lazy var nameOnCardHasText: Driver<Bool> = self.nameOnCard.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var cardNumberHasText: Driver<Bool> = self.cardNumber.asDriver().map { !$0.isEmpty }
    
    private(set) lazy var cardNumberIsValid: Driver<Bool> = self.cardNumber.asDriver().map { [weak self] in
        guard let self = self else { return false }
        return self.firstNumberCheck(cardNumber: $0) && self.luhnCheck(cardNumber: $0)
    }
    
    var cardIcon: UIImage? {
        let characters = Array(cardNumber.value)
        if characters.count < 2 {
            return nil
        }
        
        if characters[0] == "3" && (characters[1] == "4" || characters[1] == "7") { // American Express
            return #imageLiteral(resourceName: "ic_amex_mini")
        } else if (characters[0] == "5" && ["1", "2", "3", "4", "5"].contains(characters[1])) || (characters[0] == "2" && ["2", "3", "4", "5", "6", "7"].contains(characters[1])) { // Mastercard
            return #imageLiteral(resourceName: "ic_mastercard_mini")
        } else if characters[0] == "4" { // VISA
            return #imageLiteral(resourceName: "ic_visa_mini")
        } else {
            if characters.count >= 6 {
                let str = cardNumber.value[..<cardNumber.value.index(cardNumber.value.startIndex, offsetBy: 6)]
                if let doubleVal = Double(str) {
                    if (doubleVal >= Double(601100) && doubleVal <= Double(601109)) ||
                        (doubleVal >= Double(601120) && doubleVal <= Double(601149)) ||
                        (doubleVal == Double(601174)) ||
                        (doubleVal >= Double(601177) && doubleVal <= Double(601179)) ||
                        (doubleVal >= Double(601186) && doubleVal <= Double(601199)) ||
                        (doubleVal >= Double(644000) && doubleVal <= Double(659999)) {
                        return #imageLiteral(resourceName: "ic_discover_mini")
                    }
                }
            }
            return nil
        }
    }
    
    private(set) lazy var expMonthIs2Digits: Driver<Bool> = self.expMonth.asDriver().map { $0.count == 2 }
    
    private(set) lazy var expMonthIsValidMonth: Driver<Bool> = self.expMonth.asDriver().map {
        (1...12).map { String(format: "%02d", $0) }.contains($0)
    }
    
    private(set) lazy var expYearIs4Digits: Driver<Bool> = self.expYear.asDriver().map { $0.count == 4 }
    
    private(set) lazy var expYearIsNotInPast: Driver<Bool> = self.expYear.asDriver().map {
        guard let enteredDate = DateFormatter.yyyyFormatter.date(from: $0) else { return false }
        let enteredYear = Calendar.opCo.component(.year, from: enteredDate)
        let todayYear = Calendar.opCo.component(.year, from: .now)
        
        return enteredYear >= todayYear
    }

    private(set) lazy var cvvIsCorrectLength: Driver<Bool> = self.cvv.asDriver().map { $0.count == 3 || $0.count == 4 }
    
    private(set) lazy var zipCodeIs5Digits: Driver<Bool> = self.zipCode.asDriver().map { $0.count == 5 }
    
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
    
    private func luhnCheck(cardNumber: String) -> Bool {
        var oddSum = 0
        var evenSum = 0
        let reversedCharacters = cardNumber.reversed().map { String($0) }
        for (idx, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else { return false }
            if (idx % 2 == 0) {
                evenSum += digit
            } else {
                oddSum += digit / 5 + (2 * digit) % 10
            }
        }
        return (oddSum + evenSum) % 10 == 0
    }
    
    private func firstNumberCheck(cardNumber: String) -> Bool {
        guard let firstChar = cardNumber.first?.description else {
            return false
        }
        let charSet = CharacterSet(charactersIn: "23456")
        return firstChar.trimmingCharacters(in: charSet).count == 0
    }
    
}
