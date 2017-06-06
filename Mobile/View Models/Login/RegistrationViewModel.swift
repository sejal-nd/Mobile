//
//  RegistrationViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Zxcvbn

class RegistrationViewModel {
    let MAXUSERNAMECHARS = 255
    
    let disposeBag = DisposeBag()
    
    let phoneNumber = Variable("")
    let identifierNumber = Variable("")
    let accountNumber = Variable("")
    
    var username = Variable("")
    var confirmUsername = Variable("")
    var newPassword = Variable("")
    var confirmPassword = Variable("")
    var primaryProfile = false
    
    
    required init() {
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func validateAccount(onSuccess: @escaping () -> Void, onMultipleAccounts: @escaping() -> Void, onError: @escaping (String, String) -> Void) {
        let acctNum: String? = accountNumber.value.characters.count > 0 ? accountNumber.value : nil
        let identifier: String = identifierNumber.value
        
        let registrationService = ServiceFactory.createRegistrationService()
        
        registrationService.validateAccountInformation(identifier, phone: extractDigitsFrom(phoneNumber.value), accountNum: acctNum)
        	.observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                if serviceError.serviceCode == ServiceErrorCode.FnAccountNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), error.localizedDescription)
                } else if serviceError.serviceCode == ServiceErrorCode.FnAccountMultiple.rawValue {
                    onMultipleAccounts()
                } else if serviceError.serviceCode == ServiceErrorCode.FnProfileExists.rawValue {
                    onError(NSLocalizedString("Profile Exists", comment: ""), error.localizedDescription)
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    func verifyUniqueUsername(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let username: String = self.username.value
        
        let registrationService = ServiceFactory.createRegistrationService()
        
        registrationService.checkForDuplicateAccount(username)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                if serviceError.serviceCode == ServiceErrorCode.FnProfileExists.rawValue {
                    onError(NSLocalizedString("Profile Exists", comment: ""), error.localizedDescription)
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////
    func nextButtonEnabled() -> Observable<Bool> {
        if Environment.sharedInstance.opco == .bge {
            return Observable.combineLatest(phoneNumberHasTenDigits(),
                                            identifierHasFourDigits(),
                                            identifierIsNumeric()) {
            	//
                return $0 && $1 && $2
            }
        } else {
            return Observable.combineLatest(phoneNumberHasTenDigits(),
                                            accountNumberHasTenDigits(),
                                            identifierHasFourDigits(),
                                            identifierIsNumeric()) {
                //
                return $0 && $1 && $2 && $3
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
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func newUsernameHasText() -> Observable<Bool> {
        return username.asObservable().map{ text -> Bool in
            return text.characters.count > 0
    	}
    }
    
    func newUsernameIsValid() -> Observable<Bool> {
        return username.asObservable().map { text -> Bool in
            let components = text.components(separatedBy: "@")
            
            if components.count != 2 {
                return false
            }
            
            let urlComponents = components[1].components(separatedBy: ".")
            
            if urlComponents.count < 2 {
                return false
            }
            
            return true
        }
    }
    
    func usernameMatches() -> Observable<Bool> {
        return confirmUsername.asObservable().map { text -> Bool in
            return (text == self.username.value) && text.characters.count > 0
        }
    }
    
    func newPasswordHasText() -> Observable<Bool> {
        return newPassword.asObservable().map{ text -> Bool in
            return text.characters.count > 0
        }
    }
    
    func characterCountValid() -> Observable<Bool> {
        return newPassword.asObservable()
            .map{ text -> String in
                return text.components(separatedBy: .whitespacesAndNewlines).joined()
            }
            .map{ text -> Bool in
                return text.characters.count >= 8 && text.characters.count <= 16
            }
    }
    
    func usernameMax255Characters() -> Observable<Bool> {
        return username.asObservable().map({ text -> Bool in
            return text.characters.count == self.MAXUSERNAMECHARS
        })
    }
    
    func containsUppercaseLetter() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[A-Z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func containsLowercaseLetter() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[a-z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func containsNumber() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func containsSpecialCharacter() -> Observable<Bool> {
        return newPassword.asObservable()
            .map{ text -> String in
                return text.components(separatedBy: .whitespacesAndNewlines).joined()
            }
            .map({ text -> Bool in
                let regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
                return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
            })
    }
    
    func passwordMatchesUsername() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let username = self.username.value
            return (text.lowercased() == username.lowercased()) && text.characters.count > 0
        })
    }
    
    func everythingValid() -> Observable<Bool> {
        return Observable.combineLatest([passwordMatchesUsername(),
                                        characterCountValid(),
                                        containsUppercaseLetter(),
                                        containsLowercaseLetter(),
                                        containsNumber(),
                                        containsSpecialCharacter(),
                                        newUsernameHasText(),
                                        usernameMatches(),
                                        newUsernameIsValid()]) { array in
            //
                                            
            if !array[0] && array[1] && array[6] && array[7] && array[8] {
                let otherArray = array[2...5].filter{ $0 }
                
                if otherArray.count >= 3 {
                    return true
                }
            }
                                            
            return false
        }
    }
    
    func getPasswordScore() -> Int32 {
        var score: Int32 = -1
        if newPassword.value.characters.count > 0 {
            score = DBZxcvbn().passwordStrength(newPassword.value).score
        }
        return score
    }
    
    func confirmPasswordMatches() -> Observable<Bool> {
        return Observable.combineLatest(confirmPassword.asObservable(), newPassword.asObservable()) {
            return $0 == $1
        }
    }
    
    func doneButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(everythingValid(), confirmPasswordMatches(), newPasswordHasText()) {
            return $0 && $1 && $2
        }
    }
}
