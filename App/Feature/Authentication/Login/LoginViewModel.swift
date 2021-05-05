//
//  LoginViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

fileprivate let kMaxUsernameChars = 255

class LoginViewModel {
    
    let disposeBag = DisposeBag()
    
    var username = BehaviorRelay(value: "")
    var password = BehaviorRelay(value: "")
    var biometricsAutofilledPassword: String? = nil
    var biometricsEnabled = BehaviorRelay(value: false)
    var isLoggingIn = false
        
    init() {
        if let username = BiometricService.getStoredUsername() {
            self.username.accept(username)
        }
        biometricsEnabled.accept(BiometricService.isBiometricsEnabled())
    }
    
    func isDeviceBiometricCompatible() -> Bool {
        return BiometricService.deviceBiometryType() != nil
    }
    
    func biometricsString() -> String? {
        return BiometricService.deviceBiometryType()
    }
    
    func shouldPromptToEnableBiometrics() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultKeys.shouldPromptToEnableBiometrics)
    }
    
    func setShouldPromptToEnableBiometrics(_ prompt: Bool) {
        UserDefaults.standard.set(prompt, forKey: UserDefaultKeys.shouldPromptToEnableBiometrics)
    }
    
    func performLogin(onSuccess: @escaping (Bool, Bool) -> Void, onRegistrationNotComplete: @escaping () -> Void, onError: @escaping (String?, String) -> Void) {
        if username.value.isEmpty || password.value.isEmpty {
            onError(nil, "Please enter your username and password")
            return
        }
        
        isLoggingIn = true

        AuthenticationService.login(username: username.value,
                                   password: password.value) { [weak self] (result: Result<Bool, NetworkingError>) in
                                    switch result {
                                    case .success(let hasTempPassword):
                                        guard let self = self else { return }
                                        
                                        self.isLoggingIn = false
                                        
                                        if hasTempPassword {
                                            AuthenticationService.logout(resetNavigation: false)
                                            onSuccess(hasTempPassword, false)
                                        } else {
                                            self.checkStormMode { isStormMode in
                                                onSuccess(hasTempPassword, isStormMode)
                                            }
                                        }
                                    case .failure(let error):
                                        
                                        self?.isLoggingIn = false
                                        if error == .failedLogin {
                                            if FeatureFlagUtility.shared.bool(forKey: .hasNewRegistration) {
                                                if Configuration.shared.opco == .bge {
                                                    onError(nil, NSLocalizedString("We're sorry, this combination of username and password is invalid. Please try again. Too many consecutive attempts may result in your account being temporarily locked.", tableName: "ErrorMessages", comment: ""))
                                                } else {
                                                    onError(nil, NSLocalizedString("We're sorry, this combination of email and password is invalid. Please try again. Too many consecutive attempts may result in your account being temporarily locked.", tableName: "ErrorMessages", comment: ""))
                                                }
                                            } else {
                                                onError(nil, error.description)
                                            }
                                        } else if error == .invalidUser {
                                            onRegistrationNotComplete()
                                        } else {
                                            onError(error.title, error.description)
                                        }
                                    }
        }
    }
    
    func checkStormMode(completion: @escaping (Bool) -> ()) {
        AnonymousService.maintenanceMode { (result: Result<MaintenanceMode, Error>) in
            switch result {
            case .success(let maintenanceMode):
                completion(maintenanceMode.storm)
            case .failure(_):
                completion(false)
            }
        }
    }
    
    func getStoredUsername() -> String? {
        return BiometricService.getStoredUsername()
    }
    
    func storeUsername() {
        BiometricService.setStoredUsername(username: username.value)
    }
    
    func storePasswordInSecureEnclave() {
        BiometricService.setStoredPassword(password: password.value)
    }
    
    func attemptLoginWithBiometrics(onLoad: @escaping () -> Void, onDidNotLoad: @escaping () -> Void, onSuccess: @escaping (Bool, Bool) -> Void, onError: @escaping (String?, String) -> Void) {
        if let username = BiometricService.getStoredUsername(), let password = BiometricService.getStoredPassword() {
            self.username.accept(username)
            biometricsAutofilledPassword = password
            self.password.accept(password)
            onLoad()
            isLoggingIn = true
            performLogin(onSuccess: onSuccess, onRegistrationNotComplete: {}, onError: onError)
        } else {
            onDidNotLoad()
        }
    }
    
    func disableBiometrics() {
        BiometricService.disableBiometrics()
        biometricsEnabled.accept(false)
    }
    
    func checkForMaintenance(onCompletion: @escaping () -> Void) {
        AnonymousService.maintenanceMode { (result: Result<MaintenanceMode, Error>) in
            switch result {
            case .success(_):
                onCompletion()
            case .failure(_):
                onCompletion()
            }
        }
    }
    
    func validateRegistration(guid: String, onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let guidRequest = GuidRequest(guid: guid)
        RegistrationService.validateConfirmationEmail(request: guidRequest) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onError(error.title, error.description)
            }
        }
    }
    
    func resendValidationEmail(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let usernameRequest = UsernameRequest(username: username.value)
        RegistrationService.sendConfirmationEmail(request: usernameRequest) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    // MARK: - New Email/Password Validation Requirement
    
    var usernameIsValidEmailAddress: Bool {
        let username = self.username.value
        
        if username.count > kMaxUsernameChars {
            return false
        }
        
        let components = username.components(separatedBy: "@")
        
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
    
    var passwordMeetsRequirements: Bool {
        let password = self.password.value
        
        // Must be between 8-16 characters
        let passwordWithoutSpaces = password.components(separatedBy: .whitespacesAndNewlines).joined()
        if passwordWithoutSpaces.count < 8 || passwordWithoutSpaces.count > 16 {
            return false
        }
        
        // And meet at least 3 of the 4 following rules:
        
        var regex: NSRegularExpression
        var numRulesMet = 0
        
        // Contains uppercase letter
        regex = try! NSRegularExpression(pattern: ".*[A-Z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
        if regex.firstMatch(in: password, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, password.count)) != nil {
            numRulesMet += 1
        }
        
        // Contains lowercase letter
        regex = try! NSRegularExpression(pattern: ".*[a-z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
        if regex.firstMatch(in: password, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, password.count)) != nil {
            numRulesMet += 1
        }
        
        // Contains number
        regex = try! NSRegularExpression(pattern: ".*[0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
        if regex.firstMatch(in: password, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, password.count)) != nil {
            numRulesMet += 1
        }
        
        // Contains special character
        regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
        if regex.firstMatch(in: password, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, password.count)) != nil {
            numRulesMet += 1
        }
        
        return numRulesMet >= 3
    }
    
    private(set) lazy var usernameEntered: Driver<Bool> = self.username.asDriver().map { [weak self] username -> Bool in
        guard let `self` = self else { return false }
        return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private(set) lazy var passwordEntered: Driver<Bool> = self.password.asDriver().map { [weak self] password -> Bool in
        guard let `self` = self else { return false }
        return !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private(set) lazy var signInButtonEnabled: Driver<Bool> = {
        return Driver.combineLatest(self.usernameEntered,
                                      self.passwordEntered)
        { $0 && $1}
    }()
}
