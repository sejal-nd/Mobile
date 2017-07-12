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
    
    var accountDetail: AccountDetail! // Passed from WalletViewController
    
    let nameOnCard = Variable("")
    let cardNumber = Variable("")
    let expMonth = Variable("")
    let expYear = Variable("")
    let cvv = Variable("")
    let zipCode = Variable("")
    let nickname = Variable("")
    let oneTouchPay = Variable(false)
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
            return Observable.combineLatest([nameOnCardHasText(), cardNumberHasText(), cardNumberIsValid(), expMonthIs2Digits(), expMonthIsValidMonth(), expYearIs4Digits(), expYearIsNotInPast(), cvvIsCorrectLength(), zipCodeIs5Digits(), nicknameHasText(), nicknameIsValid()]) {
                return !$0.contains(false)
            }
        } else {
            return Observable.combineLatest([cardNumberHasText(), cardNumberIsValid(), expMonthIs2Digits(), expMonthIsValidMonth(), expYearIs4Digits(), expYearIsNotInPast(), cvvIsCorrectLength(), zipCodeIs5Digits(), nicknameIsValid()]) {
                return !$0.contains(false)
            }
        }
    }
    
    func nameOnCardHasText() -> Observable<Bool> {
        return nameOnCard.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func cardNumberHasText() -> Observable<Bool> {
        return cardNumber.asObservable().map {
            return !$0.isEmpty
        }
    }
    
    func cardNumberIsValid() -> Observable<Bool> {
        return cardNumber.asObservable().map {
            let luhnValid = self.luhnCheck(cardNumber: $0)
            if (Environment.sharedInstance.opco == .peco) {
                return self.pecoValidCreditCardCheck(cardNumber: $0) && luhnValid
            } else {
                return self.luhnCheck(cardNumber: $0)
            }
        }
    }
    
    func getCardIcon() -> UIImage? {
        let characters = Array(cardNumber.value.characters)
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
                let str = cardNumber.value.substring(to: cardNumber.value.index(cardNumber.value.startIndex, offsetBy: 6))
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
    
    func expMonthIs2Digits() -> Observable<Bool> {
        return expMonth.asObservable().map {
            return $0.characters.count == 2
        }
    }
    
    func expMonthIsValidMonth() -> Observable<Bool> {
        return expMonth.asObservable().map {
            return $0 == "01" || $0 == "02" || $0 == "03" || $0 == "04" || $0 == "05" || $0 == "06" || $0 == "07" || $0 == "08" || $0 == "09" || $0 == "10" || $0 == "11" || $0 == "12"
        }
    }
    
    func expYearIs4Digits() -> Observable<Bool> {
        return expYear.asObservable().map {
            return $0.characters.count == 4
        }
    }
    
    func expYearIsNotInPast() -> Observable<Bool> {
        return expYear.asObservable().map {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy"
            let enteredYear = formatter.date(from: $0)
            let todayYear = formatter.date(from: formatter.string(from: Date()))
    
            if let enteredYear = enteredYear, let todayYear = todayYear {
                return enteredYear >= todayYear
            }
            return false
        }
    }
    
    func cvvIsCorrectLength() -> Observable<Bool> {
        return cvv.asObservable().map {
            return $0.characters.count == 3 || $0.characters.count == 4
        }
    }
    
    func zipCodeIs5Digits() -> Observable<Bool> {
        return zipCode.asObservable().map {
            return $0.characters.count == 5
        }
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
    
    func addCreditCard(onDuplicate: @escaping (String) -> Void, onSuccess: @escaping (WalletItemResult) -> Void, onError: @escaping (String) -> Void) {
        
        let card = CreditCard(cardNumber: cardNumber.value, securityCode: cvv.value, firstName: "", lastName: "", expirationMonth: expMonth.value, expirationYear: expYear.value, postalCode: zipCode.value, nickname: nickname.value)
        
        walletService
            .addCreditCard(card, forCustomerNumber: AccountsStore.sharedInstance.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItemResult in
                onSuccess(walletItemResult)
            }, onError: { err in
                let serviceError = err as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.DupPaymentAccount.rawValue {
                    onDuplicate(err.localizedDescription)
                } else {
                    onError(err.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    private func luhnCheck(cardNumber: String) -> Bool {
        var sum = 0
        let reversedCharacters = cardNumber.characters.reversed().map { String($0) }
        for (idx, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else { return false }
            switch ((idx % 2 == 1), digit) {
            case (true, 9): sum += 9
            case (true, 0...8): sum += (digit * 2) % 9
            default: sum += digit
            }
        }
        return sum % 10 == 0
    }
    
    private func pecoValidCreditCardCheck(cardNumber: String) -> Bool {
        let charSet = CharacterSet(charactersIn: "23456") //peco cc can only start with these chars
        
        guard let firstChar = cardNumber.characters.first?.description else {
            return false
        }
        
        return firstChar.trimmingCharacters(in: charSet).characters.count == 0
    }
}
