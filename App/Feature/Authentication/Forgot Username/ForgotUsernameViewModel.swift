//
//  ForgotUsernameViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class ForgotUsernameViewModel {
    let disposeBag = DisposeBag()
    
    private var authService: AuthenticationService
    
    let phoneNumber = BehaviorRelay(value: "")
    let identifierNumber = BehaviorRelay(value: "")
    let accountNumber = BehaviorRelay(value: "")
    
    var maskedUsernames = [ForgotUsernameMasked]()
    var selectedUsernameIndex = 0
    
    let securityQuestionAnswer = BehaviorRelay(value: "")
    
    required init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func validateAccount(onSuccess: @escaping () -> Void, onNeedAccountNumber: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let acctNum: String? = accountNumber.value.isEmpty ? nil : accountNumber.value
        let identifier: String? = identifierNumber.value.isEmpty ? nil : identifierNumber.value
        authService.recoverMaskedUsername(phone: extractDigitsFrom(phoneNumber.value), identifier: identifier, accountNumber: acctNum)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { usernames in
                self.maskedUsernames = usernames
                onSuccess()
                GoogleAnalytics.log(event: .forgotUsernameAccountValidate)
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnAccountNotFound.rawValue ||
                    serviceError.serviceCode == ServiceErrorCode.fnProfNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), error.localizedDescription)
                } else if serviceError.serviceCode == ServiceErrorCode.fnMultiAccountFound.rawValue {
                    onNeedAccountNumber()
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }
    
    func submitSecurityQuestionAnswer(onSuccess: @escaping (String) -> Void, onAnswerNoMatch: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        let maskedUsername = maskedUsernames[selectedUsernameIndex]
        let acctNum: String? = accountNumber.value.count > 0 ? accountNumber.value : nil
        let identifier: String? = identifierNumber.value.count > 0 ? identifierNumber.value : nil
        GoogleAnalytics.log(event: .forgotUsernameSecuritySubmit)
        
        authService.recoverUsername(phone: extractDigitsFrom(phoneNumber.value),
                                    identifier: identifier,
                                    accountNumber: acctNum,
                                    questionId: maskedUsername.questionId,
                                    questionResponse: securityQuestionAnswer.value,
                                    cipher: maskedUsername.cipher)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { username in
                onSuccess(username)
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnProfBadSecurity.rawValue {
                    onAnswerNoMatch(serviceError.localizedDescription)
                } else {
                    onError(error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }
    
    func getSecurityQuestion() -> String {
        return maskedUsernames[selectedUsernameIndex].question!
    }
    
    private(set) lazy var continueButtonEnabled: Driver<Bool> = {
        if Environment.shared.opco == .bge {
            return Driver.combineLatest(self.phoneNumberHasTenDigits, self.identifierHasFourDigits, self.identifierIsNumeric)
            { $0 && $1 && $2 }
        } else {
            return Driver.combineLatest(self.phoneNumberHasTenDigits, self.accountNumberHasValidLength)
            { $0 && $1 }
        }
    }()
    
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
    
    private(set) lazy var accountNumberHasValidLength: Driver<Bool> = self.accountNumber.asDriver()
        .map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            let accountNumberLength = (Environment.shared.opco == .bge || Environment.shared.opco == .peco || Environment.shared.opco == .comEd) ? 10 : 11
            return digitsOnlyString.count == accountNumberLength
        }
    
    private(set) lazy var securityQuestionAnswerNotEmpty: Driver<Bool> = self.securityQuestionAnswer.asDriver()
        .map { $0.count > 0 }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
