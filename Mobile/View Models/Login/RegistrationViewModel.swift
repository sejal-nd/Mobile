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
    
    var accountType = Variable("")
    
    var primaryProfile = Variable<Bool>(false)
    
    let securityQuestion1 = Variable("")
    let securityAnswer1 = Variable("")
    
    let securityQuestion2 = Variable("")
    let securityAnswer2 = Variable("")
    
    let securityQuestion3 = Variable("")
    let securityAnswer3 = Variable("")
    
    var paperlessEbill = Variable<Bool>(true)
    
    var isPaperlessEbillEligible = false //not making this Rx until this VM is made Rx
    
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
    }
    
    func validateAccount(onSuccess: @escaping () -> Void, onMultipleAccounts: @escaping() -> Void, onError: @escaping (String, String) -> Void) {
        let acctNum: String? = !accountNumber.value.isEmpty ? accountNumber.value : nil
        let identifier: String = identifierNumber.value
        
        registrationService.validateAccountInformation(identifier, phone: extractDigitsFrom(phoneNumber.value), accountNum: acctNum)
        	.observeOn(MainScheduler.instance)
            .subscribe(onNext: { data in
                let types = data["type"] as? [String]
                self.accountType.value = types?.first ?? ""
                self.isPaperlessEbillEligible = (data["ebill"] as? Bool) ?? false
                
                
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
            .disposed(by: disposeBag)
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
            .disposed(by: disposeBag)
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
            .disposed(by: disposeBag)
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
            .disposed(by: disposeBag)
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
            .disposed(by: disposeBag)
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////

    // THIS IS FOR THE NEXT BUTTON ON THE FIRST STEP (VALIDATE ACCOUNT)
	private(set) lazy var nextButtonEnabled: Driver<Bool> = {
		if Environment.sharedInstance.opco == .bge {
			return Driver.combineLatest(self.phoneNumberHasTenDigits,
			                            self.identifierHasFourDigits,
			                            self.identifierIsNumeric)
			{ $0 && $1 && $2 }
		} else {
			return Driver.combineLatest(self.phoneNumberHasTenDigits,
			                            self.accountNumberHasTenDigits,
			                            self.identifierHasFourDigits,
			                            self.identifierIsNumeric)
			{ $0 && $1 && $2 && $3 }
		}
    }()
	
    func checkForMaintenance(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        var isMaintenanceMode = false
        
        authenticationService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenanceInfo in
                isMaintenanceMode = maintenanceInfo.allStatus
                onSuccess(isMaintenanceMode)
            }, onError: { error in
                _ = error as! ServiceError
            }).disposed(by: disposeBag)
    }
	
	private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> = self.phoneNumber.asDriver().map { text -> Bool in
		let digitsOnlyString = self.extractDigitsFrom(text)
		return digitsOnlyString.characters.count == 10
	}
	
    private(set) lazy var identifierHasFourDigits: Driver<Bool> = self.identifierNumber.asDriver().map { $0.characters.count == 4 }
	
	private(set) lazy var identifierIsNumeric: Driver<Bool> = self.identifierNumber.asDriver().map { text -> Bool in
		let digitsOnlyString = self.extractDigitsFrom(text)
		return digitsOnlyString.characters.count == text.characters.count
	}
	
    private(set) lazy var accountNumberHasTenDigits: Driver<Bool> = self.accountNumber.asDriver().map { text -> Bool in
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.characters.count == 10
        }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    private(set) lazy var newUsernameHasText: Driver<Bool> = self.username.asDriver().map { !$0.isEmpty }
	
	private(set) lazy var newUsernameIsValidBool: Driver<Bool> = self.username.asDriver().map { text -> Bool in
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
		} else if urlComponents[0].isEmpty || urlComponents[1].isEmpty {
			return false
		}
		
		return true
	}
	
	private(set) lazy var newUsernameIsValid: Driver<String?> = self.username.asDriver().map { text -> String? in
		if !text.isEmpty {
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
			} else if urlComponents[0].isEmpty || urlComponents[1].isEmpty {
				return "Invalid email address"
			}
		}
		
		return nil
	}
	
	private(set) lazy var usernameMatches: Driver<Bool> = Driver.combineLatest(self.confirmUsername.asDriver(), self.username.asDriver())
		.map { $0 == $1 && !$0.isEmpty }
	
	private(set) lazy var newPasswordHasText: Driver<Bool> = self.newPassword.asDriver().map{ !$0.isEmpty }
	
	private(set) lazy var characterCountValid: Driver<Bool> = self.newPassword.asDriver()
		.map{ text -> String in
			return text.components(separatedBy: .whitespacesAndNewlines).joined()
		}
		.map{ text -> Bool in
			return text.characters.count >= 8 && text.characters.count <= 16
	}
	
	private(set) lazy var usernameMaxCharacters: Driver<Bool> = self.username.asDriver().map { $0.characters.count > self.MAXUSERNAMECHARS }
	
	private(set) lazy var containsUppercaseLetter: Driver<Bool> = self.newPassword.asDriver().map { text -> Bool in
		let regex = try! NSRegularExpression(pattern: ".*[A-Z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
		return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
	}
	
	private(set) lazy var containsLowercaseLetter: Driver<Bool> = self.newPassword.asDriver().map { text -> Bool in
		let regex = try! NSRegularExpression(pattern: ".*[a-z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
		return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
	}
	
	private(set) lazy var containsNumber: Driver<Bool> = self.newPassword.asDriver().map { text -> Bool in
		let regex = try! NSRegularExpression(pattern: ".*[0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
		return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
	}
	
	private(set) lazy var containsSpecialCharacter: Driver<Bool> = self.newPassword.asDriver()
		.map{ text -> String in
			return text.components(separatedBy: .whitespacesAndNewlines).joined()
		}
		.map { text -> Bool in
			let regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
			return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
	}
	
	private(set) lazy var passwordMatchesUsername: Driver<Bool> = Driver.combineLatest(self.newPassword.asDriver(), self.username.asDriver())
	{ newPassword, username -> Bool in
		newPassword.lowercased() == username.lowercased() && !newPassword.isEmpty
	}
	
	private(set) lazy var newPasswordIsValid: Driver<Bool> = Driver.combineLatest([self.characterCountValid,
	                                                                               self.containsLowercaseLetter,
	                                                                               self.containsUppercaseLetter,
	                                                                               self.containsNumber,
	                                                                               self.containsSpecialCharacter])
	{ array in
		if array[0] {
			let otherArray = array[1...4].filter{ $0 }
			
			if otherArray.count >= 3 {
				return true
			}
		}
		
		return false
	}
	
	private(set) lazy var everythingValid: Driver<Bool> = Driver.combineLatest([self.passwordMatchesUsername,
	                                                                            self.characterCountValid,
	                                                                            self.containsUppercaseLetter,
	                                                                            self.containsLowercaseLetter,
	                                                                            self.containsNumber,
	                                                                            self.containsSpecialCharacter,
	                                                                            self.newUsernameHasText,
	                                                                            self.usernameMatches,
	                                                                            self.newUsernameIsValidBool])
	{ array in
		if !array[0] && array[1] && array[6] && array[7] && array[8] {
			let otherArray = array[2...5].filter{ $0 }
			
			if otherArray.count >= 3 {
				return true
			}
		}
		
		return false
	}
	
    func getPasswordScore() -> Int32 {
        var score: Int32 = -1
        if !newPassword.value.isEmpty {
            score = DBZxcvbn().passwordStrength(newPassword.value).score
        }
        return score
    }
    
    private(set) lazy var confirmPasswordMatches: Driver<Bool> = Driver.combineLatest(self.confirmPassword.asDriver(),
                                                                                      self.newPassword.asDriver(),
                                                                                      resultSelector: ==)
    
    // THIS IS FOR THE NEXT BUTTON ON THE SECOND STEP (CREATE SIGN IN CREDENTIALS)
    private(set) lazy var doneButtonEnabled: Driver<Bool> = Driver.combineLatest(self.everythingValid,
                                                                                 self.confirmPasswordMatches,
                                                                                 self.newPasswordHasText)
	{ $0 && $1 && $2 }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
	private(set) lazy var question1Selected: Driver<Bool> = self.securityQuestion1.asDriver().map { !$0.isEmpty }
	private(set) lazy var question2Selected: Driver<Bool> = self.securityQuestion2.asDriver().map { !$0.isEmpty }
	private(set) lazy var question3Selected: Driver<Bool> = self.securityQuestion3.asDriver().map { !$0.isEmpty }
	private(set) lazy var question1Answered: Driver<Bool> = self.securityAnswer1.asDriver().map { !$0.isEmpty }
	private(set) lazy var question2Answered: Driver<Bool> = self.securityAnswer2.asDriver().map { !$0.isEmpty }
	private(set) lazy var question3Answered: Driver<Bool> = self.securityAnswer3.asDriver().map { !$0.isEmpty }
	private(set) lazy var securityQuestionChanged: Driver<Bool> = self.selectedQuestionChanged.asDriver()
	
	private(set) lazy var allQuestionsAnswered: Driver<Bool> = {
		var inArray = [self.question1Selected,
		               self.question1Answered,
		               self.question2Selected,
		               self.question2Answered]
		
        var count = 4
		
        if Environment.sharedInstance.opco != .bge {
            inArray.append(self.question3Selected)
            inArray.append(self.question3Answered)
            
            count = 6
        }
        
        return Driver.combineLatest(inArray) { outArray in
            let otherArray = outArray[0..<count].filter{ $0 }
            
            return otherArray.count == count
        }
    }()
}
