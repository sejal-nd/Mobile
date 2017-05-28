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
    
    var isOneTouch = Variable(false)
    
    let cardNumber = Variable("")
    let expMonth = Variable("")
    let expYear = Variable("")
    let cvv = Variable("")
    let zipCode = Variable("")
    let oneTouchPay = Variable(false)
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func saveButtonIsEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
            return Observable.combineLatest([expMonthIs2Digits(), expMonthIsValidMonth(), expYearIs4Digits(), expYearIsNotInPast(), cvvIsCorrectLength(), zipCodeIs5Digits()]) {
                return !$0.contains(false)
            }
        } else {
            return Observable.combineLatest([expMonthIs2Digits(), expMonthIsValidMonth(), expYearIs4Digits(), expYearIsNotInPast(), cvvIsCorrectLength(), zipCodeIs5Digits()]) {
                return !$0.contains(false)
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
    
    func editCreditCard(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            onSuccess()
        }
    }
}
