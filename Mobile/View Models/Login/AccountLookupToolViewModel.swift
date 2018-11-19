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
            .subscribe(onNext: { [weak self] accounts in
                self?.accountLookupResults = accounts
                onSuccess()
            }, onError: { (error: Error) in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), error.localizedDescription)
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            }).disposed(by: disposeBag)
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

}
