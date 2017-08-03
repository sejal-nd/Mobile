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
    
    private var authService: AuthenticationService
    
    let phoneNumber = Variable("")
    let identifierNumber = Variable("")
    
    var accountLookupResults = [AccountLookupResult]()
    
    required init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func performSearch(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        authService.lookupAccount(phone: phoneNumber.value, identifier: identifierNumber.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { accounts in
                self.accountLookupResults = accounts
                onSuccess()
            }, onError: { (error: Error) in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), error.localizedDescription)
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            }).disposed(by: disposeBag)
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
