//
//  AccountLookupToolViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AccountLookupToolViewModel {
    let disposeBag = DisposeBag()
    
    let phoneNumber = Variable("")
    let identifierNumber = Variable("")
    
    var accountLookupResults = [AccountLookupResult]()
    
    func performSearch(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let accounts = [
            NSDictionary(dictionary: [
                "accountNumber": "123456789123456",
                "streetNumber": "1268",
                "unitNumber": "12B"
            ]),
            NSDictionary(dictionary: [
                "accountNumber": "987654321987654",
                "streetNumber": "6789",
                "unitNumber": "99A"
            ]),
            NSDictionary(dictionary: [
                "accountNumber": "111111111111111",
                "streetNumber": "999",
            ])
        ]
        for account in accounts {
            if let mockModel = AccountLookupResult.from(account) {
                accountLookupResults.append(mockModel)
            }
        }
        onSuccess()
    }
    
    func searchButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(phoneNumberHasTenDigits(), identifierHasFourDigits(), identifierIsNumeric()) {
            return $0 && $1 && $2
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
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }

}
