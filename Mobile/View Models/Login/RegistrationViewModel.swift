//
//  RegistrationViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import Zxcvbn

class RegistrationViewModel {
    let MAXUSERNAMECHARS = 255
    
    let disposeBag = DisposeBag()
    
    let phoneNumber = Variable("")
    let identifierNumber = Variable("")
    let accountNumber = Variable("")
    
    let username = Variable("")
    let confirmUsername = Variable("")
    let newPassword = Variable("")
    let confirmPassword = Variable("")
    
    var primaryProfile = Variable<Bool>(false)
    
    let securityQuestion1 = Variable("")
    let securityAnswer1 = Variable("")
    
    let securityQuestion2 = Variable("")
    let securityAnswer2 = Variable("")
    
    let securityQuestion3 = Variable("")
    let securityAnswer3 = Variable("")
    
    var paperlessEbill = Variable<Bool>(true)
    
    let loadSecurityQuestionsData = PublishSubject<Void>()
    
    var securityQuestions = Variable<[SecurityQuestion]>([])
    var selectedQuestion = ""
    var selectedQuestionRow = 0
    var selectedQuestionChanged = Variable<Bool>(false)
    
    var accounts = Variable<[AccountLookupResult]>([])
    
    var registrationService: RegistrationService
    var authenticationService: AuthenticationService
    
    required init(registrationService: RegistrationService, authenticationService: AuthenticationService) {
        self.registrationService = registrationService
        self.authenticationService = authenticationService

//        loadSecurityQuestions.elements().map {
//            $0.map(SecurityQuestion.init)
//            }
//            .bind(to:securityQuestions)
//            .addDisposableTo(disposeBag)
//        
//        loadAccounts.elements()
//            .bind(to: accounts)
//            .addDisposableTo(disposeBag)
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func validateAccount(onSuccess: @escaping () -> Void, onMultipleAccounts: @escaping() -> Void, onError: @escaping (String, String) -> Void) {
        let acctNum: String? = accountNumber.value.characters.count > 0 ? accountNumber.value : nil
        let identifier: String = identifierNumber.value
        
        registrationService.validateAccountInformation(identifier, phone: extractDigitsFrom(phoneNumber.value), accountNum: acctNum)
        	.observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                if serviceError.serviceCode == ServiceErrorCode.FnAccountNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), NSLocalizedString("The information entered does not match our records. Please try again.", comment: ""))
                } else if serviceError.serviceCode == ServiceErrorCode.FnAccountMultiple.rawValue {
                    onMultipleAccounts()
                } else if serviceError.serviceCode == ServiceErrorCode.FnProfileExists.rawValue {
                    onError(NSLocalizedString("Profile Exists", comment: ""), NSLocalizedString("An online profile already exists for this account. Please log in to view the profile.", comment: ""))
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    func verifyUniqueUsername(onSuccess: @escaping () -> Void, onEmailAlreadyExists: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let username: String = self.username.value
        
        registrationService.checkForDuplicateAccount(username)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                if serviceError.serviceCode == ServiceErrorCode.FnProfileExists.rawValue {
                    onEmailAlreadyExists()
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    func registerUser(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let username: String = self.username.value
        let password: String = self.newPassword.value
        let id: String = self.identifierNumber.value
        let phone: String = extractDigitsFrom(phoneNumber.value)
        let question1: String = securityQuestion1.value
        let answer1: String = securityAnswer1.value
        let question2: String = securityQuestion2.value
        let answer2: String = securityAnswer2.value
        let question3: String = securityQuestion3.value
        let answer3: String = securityAnswer3.value
        let primary: String = primaryProfile.value ? "true" : "false"
        let enrollEbill: String = paperlessEbill.value ? "true" : "false"
        
        registrationService.createNewAccount(username,
                                             password: password,
                                             identifier: id,
                                             phone: phone,
                                             question1: question1,
                                             answer1: answer1,
                                             question2: question2,
                                             answer2: answer2,
                                             question3: question3,
                                             answer3: answer3,
                                             isPrimary: primary,
                                             isEnrollEBill: enrollEbill)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                switch (serviceError.serviceCode) {
                case ServiceErrorCode.FnAccountMultiple.rawValue:
                    onError(NSLocalizedString("Multiple Accounts", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.FnCustomerNotFound.rawValue:
                    onError(NSLocalizedString("Customer Not Found", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.FnUserInvalid.rawValue:
                    onError(NSLocalizedString("User Invalid", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.FnUserExists.rawValue:
                    onError(NSLocalizedString("User Exists", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.FnProfileExists.rawValue:
                    onError(NSLocalizedString("Profile Exists", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.TcUnknown.rawValue:
                    fallthrough
                    
                default:
                    onError(NSLocalizedString("Unknown Error", comment: ""), error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
    func loadSecurityQuestions(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        self.registrationService.loadSecretQuestions()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { array in
                self.securityQuestions = Variable<[SecurityQuestion]>([])
                
                for question in array {
                    let securityQuestion = SecurityQuestion(question: question)
                    
                    self.securityQuestions.value.append(securityQuestion)
                }
                
                onSuccess()
            }, onError: { error in
                onError(NSLocalizedString("Unknown Error", comment: ""), error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func loadAccounts(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        self.authenticationService.lookupAccount(phone: self.extractDigitsFrom(self.phoneNumber.value) as String, identifier: self.identifierNumber.value as String)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { array in
                self.accounts.value = array as [AccountLookupResult]
                
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                switch (serviceError.serviceCode) {
                case ServiceErrorCode.FnNotFound.rawValue:
                    onError(NSLocalizedString("No Account Found", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.TcUnknown.rawValue:
                    fallthrough
                    
                default:
                    onError(NSLocalizedString("Unknown Error", comment: ""), error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }
    
//    lazy var loadSecurityQuestions: Observable<Event<[String]>> = self.loadSecurityQuestionsData
//        .flatMapLatest {
//            self.registrationService.loadSecretQuestions().debug("security").materialize()
//        }
//        .shareReplay(1)
//    
//    
//    lazy var loadAccounts: Observable<Event<[AccountLookupResult]>> = self.loadSecurityQuestionsData
//        .flatMapLatest {
//            self.authenticationService
//                .lookupAccount(phone: self.extractDigitsFrom(self.phoneNumber.value) as String, identifier: self.identifierNumber.value as String).debug("accounts")
//                .materialize()
//        }
//        .shareReplay(1)
//    
//    lazy var securityQuestionsDataFinishedLoading: Driver<Void> = Observable.zip(self.loadSecurityQuestions.elements(),
//                                                                                 self.loadAccounts.elements())
//                                                                                    .map({ _ in () })
//                                                                                    .asDriver(onErrorJustReturn: ())
//
//    lazy var loadAccountsError: Driver<String> = self.loadAccounts.errors()
//                    .map { $0.localizedDescription }
//                    .asDriver(onErrorJustReturn: "")
//    
//    lazy var loadSecurityQuestionsError: Driver<String> = self.loadSecurityQuestions.errors()
//                    .map { $0.localizedDescription }
//                    .asDriver(onErrorJustReturn: "")

    /////////////////////////////////////////////////////////////////////////////////////////////////

    // THIS IS FOR THE NEXT BUTTON ON THE FIRST STEP (VALIDATE ACCOUNT)
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
    
    func newUsernameIsValidBool() -> Observable<Bool> {
        return username.asObservable().map { text -> Bool in
            if text.characters.count > self.MAXUSERNAMECHARS {
                return false
            }
            
            let components = text.components(separatedBy: "@")
            
            if components.count != 2 {
                return false
            }
            
            let urlComponents = components[1].components(separatedBy: ".")
            
            if urlComponents.count < 2 {
                return false
            } else if urlComponents[0].characters.count == 0 || urlComponents[1].characters.count == 0 {
                return false
            }
            
            return true
        }
    }
    
    func newUsernameIsValid() -> Observable<String?> {
        return username.asObservable().map { text -> String? in
            if text.characters.count > 0 {
                if text.characters.count > self.MAXUSERNAMECHARS {
                    return "Maximum of 255 characters allowed"
                }
                
                let components = text.components(separatedBy: "@")
                
                if components.count != 2 {
                    return "Invalid email address"
                }
                
                let urlComponents = components[1].components(separatedBy: ".")
                
                if urlComponents.count < 2 {
                    return "Invalid email address"
                } else if urlComponents[0].characters.count == 0 || urlComponents[1].characters.count == 0 {
                    return "Invalid email address"
                }
            }
            
            return nil
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
    
    func usernameMaxCharacters() -> Observable<Bool> {
        return username.asObservable().map({ text -> Bool in
            return text.characters.count > self.MAXUSERNAMECHARS
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
    
    func newPasswordIsValid() -> Observable<Bool> {
        return Observable.combineLatest([characterCountValid(),
                                        containsLowercaseLetter(),
                                        containsUppercaseLetter(),
                                        containsNumber(),
                                        containsSpecialCharacter()]) { array in
            //
            if array[0] {
                let otherArray = array[1...4].filter{ $0 }
                
                if otherArray.count >= 3 {
                    return true
                }
            }
            
            return false
        }
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
                                        newUsernameIsValidBool()]) { array in
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
    
    // THIS IS FOR THE NEXT BUTTON ON THE SECOND STEP (CREATE SIGN IN CREDENTIALS)
    func doneButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(everythingValid(), confirmPasswordMatches(), newPasswordHasText()) {
            return $0 && $1 && $2
        }
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func question1Selected() -> Observable<Bool> {
        return securityQuestion1.asObservable().map ({ text -> Bool in
            return text.characters.count > 0
        })
    }

    func question2Selected() -> Observable<Bool> {
        return securityQuestion2.asObservable().map ({ text -> Bool in
            return text.characters.count > 0
        })
    }
    func question3Selected() -> Observable<Bool> {
        return securityQuestion3.asObservable().map ({ text -> Bool in
            return text.characters.count > 0
        })
    }
    
    func question1Answered() -> Observable<Bool> {
        return securityAnswer1.asObservable().map ({ text -> Bool in
            return text.characters.count > 0
        })
    }
    
    func question2Answered() -> Observable<Bool> {
        return securityAnswer2.asObservable().map ({ text -> Bool in
            return text.characters.count > 0
        })
    }
    
    func question3Answered() -> Observable<Bool> {
        return securityAnswer3.asObservable().map ({ text -> Bool in
            return text.characters.count > 0
        })
    }
    
    func securityQuestionChanged() -> Observable<Bool> {
        return selectedQuestionChanged.asObservable().map ({ value -> Bool in
            return value
        })
    }
    
    func allQuestionsAnswered() -> Observable<Bool> {
        var inArray = [question1Selected(),
                     question1Answered(),
                     question2Selected(),
                     question2Answered()]
        
        var count = 4
        
        if Environment.sharedInstance.opco != .bge {
            inArray.append(question3Selected())
            inArray.append(question3Answered())
            
            count = 6
        }
        
        return Observable.combineLatest(inArray) { outArray in
            let otherArray = outArray[0..<count].filter{ $0 }
            
            return otherArray.count == count
        }
    }
}
