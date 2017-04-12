//
//  ForgotUsernameViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ForgotUsernameViewModel {
    let disposeBag = DisposeBag()
    
    let phoneNumber = Variable("")
    let identifierNumber = Variable("")
    let accountNumber = Variable("")
    
    func validateAccount(onSuccess: @escaping () -> Void, onNeedAccountNumber: @escaping () -> Void, onError: @escaping (String) -> Void) {
        print("Phone number: \(extractDigitsFrom(phoneNumber.value))")
        print("Identifier number: \(identifierNumber.value)")
        print("Account number: \(accountNumber.value)")
        
        //onError(NSLocalizedString("The information entered does not match our records. Please try again.", comment: ""))
        if accountNumber.value.characters.count > 0 {
            onSuccess()
        } else {
            onNeedAccountNumber()
        }
        
    }
    
    func nextButtonEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == "BGE" {
            return Observable.combineLatest(phoneNumberHasTenDigits(), identifierHasFourDigits(), identifierIsNumeric()) {
                return $0 && $1 && $2
            }
        } else {
            return Observable.combineLatest(phoneNumberHasTenDigits(), accountNumberNotEmpty()) {
                return $0 && $1
            }
        }
    }
    
    func phoneNumberHasTenDigits() -> Observable<Bool> {
        return phoneNumber.asObservable().map({ text -> Bool in
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.characters.count == 10
        })
    }
    
    func identifierHasFourDigits() -> Observable<Bool> {
        return identifierNumber.asObservable().map({ text -> Bool in
            return text.characters.count == 4
        })
    }
    
    func identifierIsNumeric() -> Observable<Bool> {
        return identifierNumber.asObservable().map({ text -> Bool in
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.characters.count == text.characters.count
        })
    }
    
    func accountNumberNotEmpty() -> Observable<Bool> {
        return accountNumber.asObservable().map({ text -> Bool in
            return text.characters.count > 0
        })
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
