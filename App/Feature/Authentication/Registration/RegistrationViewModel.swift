//
//  RegistrationViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import zxcvbn_ios

fileprivate let kMaxUsernameChars = 255

class RegistrationViewModel {
    
    let disposeBag = DisposeBag()
    
    let phoneNumber = BehaviorRelay(value: "")
    let identifierNumber = BehaviorRelay(value: "")
    let accountNumber = BehaviorRelay(value: "")
    
    let username = BehaviorRelay(value: "")
    let newPassword = BehaviorRelay(value: "")
    let confirmPassword = BehaviorRelay(value: "")
    
    var accountType = BehaviorRelay(value: "")
    
    var primaryProfile = BehaviorRelay<Bool>(value: false)
    
    let securityQuestion1 = BehaviorRelay<String?>(value: nil)
    let securityAnswer1 = BehaviorRelay(value: "")
    
    let securityQuestion2 = BehaviorRelay<String?>(value: nil)
    let securityAnswer2 = BehaviorRelay(value: "")
    
    let securityQuestion3 = BehaviorRelay<String?>(value: nil)
    let securityAnswer3 = BehaviorRelay(value: "")
    
    var paperlessEbill = BehaviorRelay<Bool>(value: true)
    
    var isPaperlessEbillEligible = false
    
    var securityQuestions: [String]?
    
    var accounts = BehaviorRelay<[AccountLookupResult]>(value: [])
    
    var registrationService: RegistrationService
    var authenticationService: AuthenticationService
    
    var hasStrongPassword = false // Keeps track of strong password for Analytics
    
    required init(registrationService: RegistrationService, authenticationService: AuthenticationService) {
        self.registrationService = registrationService
        self.authenticationService = authenticationService
    }
    
    func validateAccount(onSuccess: @escaping () -> Void,
                         onMultipleAccounts: @escaping() -> Void,
                         onError: @escaping (String, String) -> Void) {
        let identifier: String = identifierNumber.value
        
        registrationService.validateAccountInformation(identifier,
                                                       phone: extractDigitsFrom(phoneNumber.value),
                                                       accountNum: accountNumber.value,
                                                       dueAmount: "",
                                                       dueDate: "")
        	.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                let types = data["type"] as? [String]
                self.accountType.accept(types?.first ?? "")
                self.isPaperlessEbillEligible = (data["ebill"] as? Bool) ?? false
                
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                if serviceError.serviceCode == ServiceErrorCode.fnAccountNotFound.rawValue {
                    onError(NSLocalizedString("Invalid Information", comment: ""), NSLocalizedString("The information entered does not match our records. Please try again.", comment: ""))
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountMultiple.rawValue {
                    onMultipleAccounts()
                } else if serviceError.serviceCode == ServiceErrorCode.fnProfileExists.rawValue {
                    onError(NSLocalizedString("Profile Exists", comment: ""), NSLocalizedString("An online profile already exists for this account. Please log in to view the profile.", comment: ""))
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func verifyUniqueUsername(onSuccess: @escaping () -> Void,
                              onEmailAlreadyExists: @escaping () -> Void,
                              onError: @escaping (String, String) -> Void) {
        registrationService.checkForDuplicateAccount(username.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if #available(iOS 12.0, *) {
                    onSuccess()
                } else { // Manually save to SWC if iOS 11
                    guard let this = self else { return }
                    SharedWebCredentials.save(credential: (this.username.value, this.newPassword.value), domain: Environment.shared.associatedDomain) { [weak this] error in
                        DispatchQueue.main.async {
                            if error != nil, this?.hasStrongPassword ?? false {
                                onError(NSLocalizedString("Failed to Save Password", comment: ""), NSLocalizedString("Please make sure AutoFill is on in Safari Settings for Names and Passwords when using Strong Passwords.", comment: ""))
                            } else {
                                onSuccess()
                            }
                        }
                    }
                }
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnProfileExists.rawValue {
                    onEmailAlreadyExists()
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func registerUser(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        registrationService.createNewAccount(username: username.value,
                                             password: newPassword.value,
                                             accountNum: accountNumber.value,
                                             identifier: identifierNumber.value,
                                             phone: extractDigitsFrom(phoneNumber.value),
                                             question1: securityQuestion1.value!,
                                             answer1: securityAnswer1.value,
                                             question2: securityQuestion2.value!,
                                             answer2: securityAnswer2.value,
                                             question3: securityQuestion3.value ?? "", // "" for BGE since no 3rd question
                                             answer3: securityAnswer3.value,
                                             isPrimary: primaryProfile.value ? "true" : "false",
                                             isEnrollEBill: (isPaperlessEbillEligible && paperlessEbill.value) ? "true" : "false")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                switch (serviceError.serviceCode) {
                case ServiceErrorCode.fnAccountMultiple.rawValue:
                    onError(NSLocalizedString("Multiple Accounts", comment: ""), error.localizedDescription)
            
                case ServiceErrorCode.fnCustomerNotFound.rawValue:
                    onError(NSLocalizedString("Customer Not Found", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.fnUserInvalid.rawValue:
                    onError(NSLocalizedString("User Invalid", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.fnUserExists.rawValue:
                    onError(NSLocalizedString("User Exists", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.fnProfileExists.rawValue:
                    onError(NSLocalizedString("Profile Exists", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.tcUnknown.rawValue:
                    fallthrough
                    
                default:
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func loadSecurityQuestions(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        registrationService.loadSecretQuestions()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] array in
                guard let self = self else { return }
                self.securityQuestions = array
                onSuccess()
            }, onError: { error in
                onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func loadAccounts(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        authenticationService.lookupAccount(phone: extractDigitsFrom(phoneNumber.value), identifier: identifierNumber.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] array in
                self?.accounts.accept(array)
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                
                switch (serviceError.serviceCode) {
                case ServiceErrorCode.fnNotFound.rawValue:
                    onError(NSLocalizedString("No Account Found", comment: ""), error.localizedDescription)
                    
                case ServiceErrorCode.tcUnknown.rawValue:
                    fallthrough
                    
                default:
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }

	private(set) lazy var validateAccountContinueEnabled: Driver<Bool> = {
		if Environment.shared.opco == .bge {
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
	
    func checkForMaintenance() {
        authenticationService
            .getMaintenanceMode()
            .subscribe()
            .disposed(by: disposeBag)
    }
	
	private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> =
        self.phoneNumber.asDriver().map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
        }
	
    private(set) lazy var identifierHasFourDigits: Driver<Bool> =
        self.identifierNumber.asDriver().map { $0.count == 4 }
	
    private(set) lazy var identifierIsNumeric: Driver<Bool> =
        self.identifierNumber.asDriver().map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == text.count
        }
    
    private(set) lazy var accountNumberHasTenDigits: Driver<Bool> =
        self.accountNumber.asDriver().map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
        }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
    private(set) lazy var newUsernameHasText: Driver<Bool> =
        self.username.asDriver().map { !$0.isEmpty }
	
	private(set) lazy var newUsernameIsValidBool: Driver<Bool> =
        self.username.asDriver().map { text -> Bool in
            if text.count > kMaxUsernameChars {
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
	
	private(set) lazy var newUsernameIsValid: Driver<String?> =
        self.username.asDriver().map { text -> String? in
            if !text.isEmpty {
                if text.count > kMaxUsernameChars {
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
	
	private(set) lazy var newPasswordHasText: Driver<Bool> =
        self.newPassword.asDriver().map{ !$0.isEmpty }
	
	private(set) lazy var characterCountValid: Driver<Bool> = self.newPassword.asDriver()
		.map{ $0.components(separatedBy: .whitespacesAndNewlines).joined() }
		.map{ 8...16 ~= $0.count }
	
	private(set) lazy var usernameMaxCharacters: Driver<Bool> =
        self.username.asDriver().map { $0.count > kMaxUsernameChars }
	
	private(set) lazy var containsUppercaseLetter: Driver<Bool> =
        self.newPassword.asDriver().map { text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[A-Z].*",
                                                 options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text,
                                    options: NSRegularExpression.MatchingOptions.init(rawValue: 0),
                                    range: NSMakeRange(0, text.count)) != nil
        }
	
	private(set) lazy var containsLowercaseLetter: Driver<Bool> =
        self.newPassword.asDriver().map { text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[a-z].*",
                                                 options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text,
                                    options: NSRegularExpression.MatchingOptions.init(rawValue: 0),
                                    range: NSMakeRange(0, text.count)) != nil
        }
	
	private(set) lazy var containsNumber: Driver<Bool> = self.newPassword.asDriver().map { text -> Bool in
		let regex = try! NSRegularExpression(pattern: ".*[0-9].*",
                                             options: NSRegularExpression.Options.useUnixLineSeparators)
		return regex.firstMatch(in: text,
                                options: NSRegularExpression.MatchingOptions.init(rawValue: 0),
                                range: NSMakeRange(0, text.count)) != nil
	}
	
	private(set) lazy var containsSpecialCharacter: Driver<Bool> = self.newPassword.asDriver()
		.map{ text -> String in
			return text.components(separatedBy: .whitespacesAndNewlines).joined()
		}
		.map { text -> Bool in
			let regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
			return regex.firstMatch(in: text,
                                    options: NSRegularExpression.MatchingOptions.init(rawValue: 0),
                                    range: NSMakeRange(0, text.count)) != nil
	}
	
	private(set) lazy var passwordMatchesUsername: Driver<Bool> =
        Driver.combineLatest(self.newPassword.asDriver(),
                             self.username.asDriver())
        { newPassword, username -> Bool in
            newPassword.lowercased() == username.lowercased() && !newPassword.isEmpty
        }
	
	private(set) lazy var newPasswordIsValid: Driver<Bool> =
        Driver.combineLatest([self.characterCountValid,
                              self.containsLowercaseLetter,
                              self.containsUppercaseLetter,
                              self.containsNumber,
                              self.containsSpecialCharacter])
        { array in
            if array[0] {
                let otherArray = array[1...4].filter { $0 }
                if otherArray.count >= 3 {
                    return true
                }
            }
            return false
        }
	
	private(set) lazy var everythingValid: Driver<Bool> =
        Driver.combineLatest([self.passwordMatchesUsername,
                            self.characterCountValid,
                            self.containsUppercaseLetter,
                            self.containsLowercaseLetter,
                            self.containsNumber,
                            self.containsSpecialCharacter,
                            self.newUsernameHasText,
                            self.newUsernameIsValidBool])
        { array in
            if !array[0] && array[1] && array[6] && array[7] {
                let otherArray = array[2...5].filter { $0 }
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
    
    private(set) lazy var confirmPasswordMatches: Driver<Bool> =
        Driver.combineLatest(self.confirmPassword.asDriver(), self.newPassword.asDriver(), resultSelector: ==)
    
    private(set) lazy var createCredentialsContinueEnabled: Driver<Bool> = Driver
        .combineLatest(everythingValid, confirmPasswordMatches, newPasswordHasText)
        { $0 && $1 && $2 }
    
	private(set) lazy var allQuestionsAnswered: Driver<Bool> = {
        let driverArray: [Driver<String>]
        let count: Int
        if Environment.shared.opco == .bge {
            driverArray = [self.securityAnswer1.asDriver(),
                           self.securityAnswer2.asDriver()]
            count = 2
        } else {
            driverArray = [self.securityAnswer1.asDriver(),
                           self.securityAnswer2.asDriver(),
                           self.securityAnswer3.asDriver()]
            count = 3
        }
        
        return Driver.combineLatest(driverArray) { outArray in
            let emptiesRemoved = outArray.filter { !$0.isEmpty }
            return emptiesRemoved.count == count
        }
    }()
}
