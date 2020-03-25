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

    var username = Variable("")
    var password = Variable("")
    var biometricsAutofilledPassword: String? = nil
    var keepMeSignedIn = Variable(false)
    var biometricsEnabled = Variable(false)
    var isLoggingIn = false

    private var authService: AuthenticationService
    private var biometricsService: BiometricsService
    private var registrationService: RegistrationService

    init(authService: AuthenticationService, biometricsService: BiometricsService, registrationService: RegistrationService) {
        self.authService = authService
        self.biometricsService = biometricsService
        self.registrationService = registrationService

        if let username = biometricsService.getStoredUsername() {
            self.username.value = username
        }
        biometricsEnabled.value = biometricsService.isBiometricsEnabled()
    }

    func isDeviceBiometricCompatible() -> Bool {
        return biometricsService.deviceBiometryType() != nil
    }

    func biometricsString() -> String? {
        return biometricsService.deviceBiometryType()
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
//        AuthenticatedService.login(username: username.value, password: password.value) { [weak self] (result: Result<Void, Error>) in
//            switch result {
//            case .success(()):
////                guard let self = self else { return }
//
//                onSuccess(false, false)
//
////                self.isLoggingIn = false
//                                // todo temp password
////                let tempPassword = profileStatus.tempPassword
////                if tempPassword {
////                    onSuccess(tempPassword, false)
////                    self.authService.logout()
////                } else {
////                    if #available(iOS 12.0, *) { }
////                        // Save to SWC if iOS 11. In iOS 12 the system handles this automagically
////                    else {
////                        SharedWebCredentials.save(credential: (self.username.value, self.password.value), domain: Environment.shared.associatedDomain, completion: { _ in })
////                    }
//
////                    self.checkStormMode { isStormMode in
////                        onSuccess(tempPassword, isStormMode)
////                    }
////                }
//            case .failure(let error):
//                print("Error new fetch login: \(error)")
//                self?.isLoggingIn = false
//
//                onError("temp1", "temp2")
//
////                let serviceError = error as! ServiceError
////                if serviceError.serviceCode == ServiceErrorCode.fnAccountProtected.rawValue {
////                    onError(NSLocalizedString("Password Protected Account", comment: ""), serviceError.localizedDescription)
////                } else if serviceError.serviceCode == ServiceErrorCode.fnAcctNotActivated.rawValue {
////                    onRegistrationNotComplete()
////                } else {
////                    onError(nil, error.localizedDescription)
////                }
////                GoogleAnalytics.log(event: .loginError, dimensions: [.errorCode: serviceError.serviceCode])
//            }
//        }


        authService.login(username: username.value, password: password.value, stayLoggedIn:keepMeSignedIn.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] profileStatus in
                guard let self = self else { return }
                self.isLoggingIn = false
                let tempPassword = profileStatus.tempPassword
                if tempPassword {
                    onSuccess(tempPassword, false)
                    self.authService.logout()
                } else {
                    if #available(iOS 12.0, *) { }
                        // Save to SWC if iOS 11. In iOS 12 the system handles this automagically
                    else {
                        SharedWebCredentials.save(credential: (self.username.value, self.password.value), domain: Environment.shared.associatedDomain, completion: { _ in })
                    }

                    self.checkStormMode { isStormMode in
                        onSuccess(tempPassword, isStormMode)
                    }
                }
            }, onError: { [weak self] error in
                self?.isLoggingIn = false
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnAccountProtected.rawValue {
                    onError(NSLocalizedString("Password Protected Account", comment: ""), serviceError.localizedDescription)
                } else if serviceError.serviceCode == ServiceErrorCode.fnAcctNotActivated.rawValue {
                    onRegistrationNotComplete()
                } else {
                    onError(nil, error.localizedDescription)
                }
                GoogleAnalytics.log(event: .loginError, dimensions: [.errorCode: serviceError.serviceCode])
            })
            .disposed(by: disposeBag)
    }

    func checkStormMode(completion: @escaping (Bool) -> ()) {
        AnonymousService.maintenanceMode { (result: Result<NewMaintenanceMode, Error>) in
            switch result {
            case .success(let maintenanceMode):
                completion(maintenanceMode.storm)
            case .failure(_):
                completion(false)
            }
        }
    }

    func getStoredUsername() -> String? {
        return biometricsService.getStoredUsername()
    }

    func storeUsername() {
        biometricsService.setStoredUsername(username: username.value)
    }

    func storePasswordInSecureEnclave() {
        biometricsService.setStoredPassword(password: password.value)
    }

    func attemptLoginWithBiometrics(onLoad: @escaping () -> Void, onDidNotLoad: @escaping () -> Void, onSuccess: @escaping (Bool, Bool) -> Void, onError: @escaping (String?, String) -> Void) {
        if let username = biometricsService.getStoredUsername(), let password = biometricsService.getStoredPassword() {
            self.username.value = username
            biometricsAutofilledPassword = password
            self.password.value = password
            onLoad()
            isLoggingIn = true
            performLogin(onSuccess: onSuccess, onRegistrationNotComplete: {}, onError: onError)
        } else {
            onDidNotLoad()
        }
    }

    func disableBiometrics() {
        biometricsService.disableBiometrics()
        biometricsEnabled.value = false
    }

    func checkForMaintenance(onCompletion: @escaping () -> Void) {
        AnonymousService.maintenanceMode { (result: Result<NewMaintenanceMode, Error>) in
            switch result {
            case .success(_):
                onCompletion()
            case .failure(_):
                onCompletion()
            }
        }
    }

    func validateRegistration(guid: String, onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        registrationService.validateConfirmationEmail(guid)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { err in
                let serviceError = err as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnProfNotFound.rawValue {
                    onError(NSLocalizedString("Your verification link is no longer valid", comment: ""), NSLocalizedString("If you have already verified your account, please sign in to access your account. If your link has expired, please re-register.", comment: ""))
                } else {
                    onError(NSLocalizedString("Error", comment: ""), err.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }

    func resendValidationEmail(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        registrationService.resendConfirmationEmail(username.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
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

}
