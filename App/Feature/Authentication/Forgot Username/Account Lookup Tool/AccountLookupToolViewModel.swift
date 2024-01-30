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
    let sixDigitPinNumber = BehaviorRelay(value: "")
    
    var accountLookupResults = [AccountLookupResult]()
    var validatePinResult = ValidatePinResult()
    var sendCodeResult = SendPinResult()
    let selectedAccount = BehaviorRelay<AccountLookupResult?>(value: nil)
    let selectedValidatedPinAccount = BehaviorRelay<AccountDetails?>(value: nil)
    var maskedUsernames = [ForgotMaskedUsername]()
    var selectedUsernameIndex = 0
        
    func validateAccount(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let identifier: String? = identifierNumber.value.isEmpty ? nil : identifierNumber.value
        
        var recoverMaskedUsernameRequest = RecoverMaskedUsernameRequestWithAuid(phone: "", identifier: "", auid: nil)
        
        if(selectedAccount.value != nil){
            recoverMaskedUsernameRequest = RecoverMaskedUsernameRequestWithAuid(phone: extractDigitsFrom(phoneNumber.value),identifier: identifier ?? "")
        }else if(selectedValidatedPinAccount.value != nil){
            recoverMaskedUsernameRequest = RecoverMaskedUsernameRequestWithAuid(phone: extractDigitsFrom(phoneNumber.value),identifier: identifier ?? "",auid: selectedValidatedPinAccount.value?.auid ?? "")
        }
        
        AnonymousService.recoverMaskedUsernameWithAuid(request: recoverMaskedUsernameRequest) { [weak self]
            result in switch result {
            case .success(let recoverMaskedUserNameResult):
                self?.maskedUsernames = recoverMaskedUserNameResult.maskedUsernames
                onSuccess()
            case .failure(let error):
                onError(error.title, error.description)
            }
            
        }
    }
    
    func performSearch(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let accountLookupRequest = AccountLookupRequest(phone: phoneNumber.value,
        identifier: identifierNumber.value)
        
        AnonymousService.lookupAccount(request: accountLookupRequest) { [weak self] result in
            switch result {
            case .success(let accountLookupResults):
                self?.accountLookupResults = accountLookupResults
                onSuccess()
            case .failure(let error):
                onError(error.title, error.description)
            }
        }
    }
    
    func validateSixDigitCode (onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let validateCodeRequest = ValidateCodeRequest(phone: phoneNumber.value.withoutSpecialCharacters,flowType: "ForgotUser",
                                                      pin: sixDigitPinNumber.value)
        
        AnonymousService.validateCodeAnon(request: validateCodeRequest) { [weak self] result in
            switch result {
            case .success(let validatePinResult):
                self?.validatePinResult = validatePinResult
                onSuccess()
            case .failure(let error):
                onError(error.title, error.description)
            }
        }
    }
    
    func sendSixDigitCode(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let accountLookupRequest = SendCodeRequest(phone: phoneNumber.value.withoutSpecialCharacters,flowType: "ForgotUser",
                                                   isMobile: true)
        AnonymousService.sendCodeAnon(request: accountLookupRequest) { [weak self] result in
            switch result {
            case .success(let sendPinResult):
                self?.sendCodeResult = sendPinResult
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
    
    private(set) lazy var continueButtonEnabled: Driver<Bool> = self.phoneNumberHasTenDigits.asDriver()
    
    private(set) lazy var continuePinButtonEnabled: Driver<Bool> = self.pinHasSixDigits.asDriver()
    
    private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> = self.phoneNumber.asDriver()
        .map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
    }
    
    private(set) lazy var identifierHasFourDigits: Driver<Bool> = self.identifierNumber.asDriver()
        .map { $0.count == 4 }
    
    private(set) lazy var pinHasSixDigits: Driver<Bool> = self.sixDigitPinNumber.asDriver()
        .map { $0.count == 6 }
    
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
    
    private(set) lazy var selectValidatedAccountButtonEnabled: Driver<Bool> =
        self.selectedValidatedPinAccount.asDriver().isNil().not()

}
// Mark : extension for removing special char from phone no
extension String {
    var withoutSpecialCharacters: String {
        return self.components(separatedBy: CharacterSet.punctuationCharacters).joined(separator: "").components(separatedBy: .whitespaces).joined()
    }
}
