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
    
    private var authService: AuthenticationService
    
    let phoneNumber = Variable("")
    let identifierNumber = Variable("")
    let accountNumber = Variable("")
    
    var maskedUsernames = [ForgotUsernameMasked]()
    var selectedUsernameIndex = 0
    
    let securityQuestionAnswer = Variable("")
    
    required init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func validateAccount(onSuccess: @escaping () -> Void, onNeedAccountNumber: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let acctNum: String? = accountNumber.value.characters.count > 0 ? accountNumber.value : nil
        let identifier: String? = identifierNumber.value.characters.count > 0 ? identifierNumber.value : nil
        authService.recoverMaskedUsername(phone: extractDigitsFrom(phoneNumber.value), identifier: identifier, accountNumber: acctNum)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { usernames in
                self.maskedUsernames = usernames
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnAccountNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), error.localizedDescription)
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            }).addDisposableTo(disposeBag)
    }
    
    func submitSecurityQuestionAnswer(onSuccess: @escaping (String) -> Void, onAnswerNoMatch: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        let maskedUsername = maskedUsernames[selectedUsernameIndex]
        let cipher = maskedUsername.cipher
        let acctNum: String? = accountNumber.value.characters.count > 0 ? accountNumber.value : nil
        let identifier: String? = identifierNumber.value.characters.count > 0 ? identifierNumber.value : nil
        authService.recoverUsername(phone: extractDigitsFrom(phoneNumber.value), identifier: identifier, accountNumber: acctNum, questionId: maskedUsername.questionId, questionResponse: securityQuestionAnswer.value, cipher: cipher)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { username in
                onSuccess(username)
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnProfBadSecurity.rawValue {
                    onAnswerNoMatch(serviceError.errorDescription!)
                } else {
                    onError(error.localizedDescription)
                }
            }).addDisposableTo(disposeBag)
    }
    
    func getSecurityQuestion() -> String {
        return maskedUsernames[selectedUsernameIndex].question!
    }
    
    func nextButtonEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
            return Observable.combineLatest(phoneNumberHasTenDigits(), identifierHasFourDigits(), identifierIsNumeric()) {
                return $0 && $1 && $2
            }
        } else {
            return Observable.combineLatest(phoneNumberHasTenDigits(), accountNumberHasTenDigits()) {
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
    
    func accountNumberHasTenDigits() -> Observable<Bool> {
        return accountNumber.asObservable().map({ text -> Bool in
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.characters.count == 10
        })
    }
    
    func securityQuestionAnswerNotEmpty() -> Observable<Bool> {
        return securityQuestionAnswer.asObservable().map({ text -> Bool in
            return text.characters.count > 0
        })
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
