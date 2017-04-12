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
    
    var maskedUsernames = [ForgotUsernameMasked]()
    var selectedUsernameIndex = 0
    
    let securityQuestionAnswer = Variable("")
    
    func validateAccount(onSuccess: @escaping () -> Void, onNeedAccountNumber: @escaping () -> Void, onError: @escaping (String) -> Void) {
        print("Phone number: \(extractDigitsFrom(phoneNumber.value))")
        print("Identifier number: \(identifierNumber.value)")
        print("Account number: \(accountNumber.value)")
        
        //onError(NSLocalizedString("The information entered does not match our records. Please try again.", comment: ""))
        if accountNumber.value.characters.count > 0 {
            let usernames = [
                NSDictionary(dictionary: [
                    "email": "m**********g@gmail.com",
                    "question": "What is your father's middle name?",
                    "question_id": 1
                ]),
//                NSDictionary(dictionary: [
//                    "email": "m**********g@mindgrub.com",
//                    "question": "What is your mother's maiden name?",
//                    "question_id": 4
//                ]),
//                NSDictionary(dictionary: [
//                    "email": "m**********g@icloud.com",
//                    "question": "What street did you grow up on?",
//                    "question_id": 3
//                ])
            ]
            for user in usernames {
                if let mockModel = ForgotUsernameMasked.from(user) {
                    maskedUsernames.append(mockModel)
                }
            }

            onSuccess()
        } else {
            onNeedAccountNumber()
        }
        
    }
    
    func submitSecurityQuestionAnswer(onSuccess: @escaping (String) -> Void, onAnswerNoMatch: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        onSuccess("mshilling@mindgrub.com")
        
//        let serviceError = ServiceError(serviceCode: "FN-PROF-BADSECURITY")
//        onAnswerNoMatch(serviceError.errorDescription!)
    }
    
    func nextButtonEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == "BGE" {
            return Observable.combineLatest(phoneNumberHasTenDigits(), identifierHasFourDigits()) {
                return $0 && $1
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
    
    func accountNumberNotEmpty() -> Observable<Bool> {
        return accountNumber.asObservable().map({ text -> Bool in
            return text.characters.count > 0
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
