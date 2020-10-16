//
//  AccountLookupToolViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AccountLookupToolViewModel {
    let disposeBag = DisposeBag()
        
    let phoneNumber = BehaviorRelay(value: "")
    let identifierNumber = BehaviorRelay(value: "")
    
    var accountLookupResults = [AccountLookupResult]()
    let selectedAccount = BehaviorRelay<AccountLookupResult?>(value: nil)
    
    func performSearch(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let accountLookupRequest = AccountLookupRequest(phone: phoneNumber.value,
        identifier: identifierNumber.value)
        
        AnonymousService.lookupAccount(request: accountLookupRequest) { [weak self] result in
            switch result {
            case .success(let accountLookupResults):
                self?.accountLookupResults = accountLookupResults.accountLookupResults
                onSuccess()
            case .failure(let error):
                onError(error.title, error.description)
            }
        }
    }
    
    private(set) lazy var searchButtonEnabled: Driver<Bool> = Driver.combineLatest(self.phoneNumberHasTenDigits,
                                                                                   self.identifierHasFourDigits,
                                                                                   self.identifierIsNumeric)
    { $0 && $1 && $2 }
    
    private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> = self.phoneNumber.asDriver()
        .map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
    }
    
    private(set) lazy var identifierHasFourDigits: Driver<Bool> = self.identifierNumber.asDriver()
        .map { $0.count == 4 }
    
    private(set) lazy var identifierIsNumeric: Driver<Bool> = self.identifierNumber.asDriver()
        .map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == text.count
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    private(set) lazy var selectAccountButtonEnabled: Driver<Bool> =
        self.selectedAccount.asDriver().isNil().not()

}
