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
    
    let phoneNumber = BehaviorRelay(value: "")
    let identifierNumber = BehaviorRelay(value: "")
    let accountNumber = BehaviorRelay(value: "")
    
    var maskedUsernames = [ForgotMaskedUsername]()
    var selectedUsernameIndex = 0
    
    let securityQuestionAnswer = BehaviorRelay(value: "")

    func validateAccount(onSuccess: @escaping () -> Void, onNeedAccountNumber: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let acctNum: String? = accountNumber.value.isEmpty ? nil : accountNumber.value
        let identifier: String? = identifierNumber.value.isEmpty ? nil : identifierNumber.value
        
        let recoverMaskedUsernameRequest = RecoverMaskedUsernameRequest(phone: extractDigitsFrom(phoneNumber.value),
                                                                  identifier: identifier ?? "",
                                                                  accountNumber: acctNum ?? "")
        
        AnonymousService.recoverMaskedUsername(request: recoverMaskedUsernameRequest) { result in
            switch result {
            case .success(let forgotMaskedUsernameRequest):
                self.maskedUsernames = forgotMaskedUsernameRequest.maskedUsernames
                onSuccess()
                GoogleAnalytics.log(event: .forgotUsernameAccountValidate)
            case .failure(let error):
                if error == .multiAccount {
                    onNeedAccountNumber()
                } else {
                    onError(error.title, error.description)
                }
            }
        }
    }
    
    func submitSecurityQuestionAnswer(onSuccess: @escaping (String) -> Void, onAnswerNoMatch: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        let maskedUsername = maskedUsernames[selectedUsernameIndex]
        let acctNum: String? = accountNumber.value.count > 0 ? accountNumber.value : nil
        let identifier: String? = identifierNumber.value.count > 0 ? identifierNumber.value : nil
        GoogleAnalytics.log(event: .forgotUsernameSecuritySubmit)
        
        let recoverUsernameRequest = RecoverUsernameRequest(phone: extractDigitsFrom(phoneNumber.value),
                                                            identifier: identifier,
                                                            accountNumber: acctNum,
                                                            questionId: String(maskedUsername.questionId ?? 0),
                                                            securityAnswer: securityQuestionAnswer.value,
                                                            cipherString: maskedUsername.cipher ?? "")
        
        AnonymousService.recoverUsername(request: recoverUsernameRequest, completion: { result in
            switch result {
            case .success(let username):
                onSuccess(username)
            case .failure(let error):
                if error == .incorrectSecurityQuestion {
                    onAnswerNoMatch(error.description)
                } else {
                    onError(error.description)
                }
            }
        })
    }
    
    func getSecurityQuestion() -> String {
        return maskedUsernames[selectedUsernameIndex].question!
    }
    
    private(set) lazy var continueButtonEnabled: Driver<Bool> = {
        if Configuration.shared.opco == .bge {
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
            let accountNumberLength = (Configuration.shared.opco == .bge || Configuration.shared.opco == .peco || Configuration.shared.opco == .comEd) ? 10 : 11
            return digitsOnlyString.count == accountNumberLength
        }
    
    private(set) lazy var securityQuestionAnswerNotEmpty: Driver<Bool> = self.securityQuestionAnswer.asDriver()
        .map { $0.count > 0 }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
