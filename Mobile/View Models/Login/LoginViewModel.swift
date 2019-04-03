//
//  LoginViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

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
                    else if #available(iOS 11.0, *) {
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
                Analytics.log(event: .loginError, dimensions: [.errorCode: serviceError.serviceCode])
            })
            .disposed(by: disposeBag)
    }

    func checkStormMode(completion: @escaping (Bool) -> ()) {
        authService.getMaintenanceMode(postNotification: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenance in
                completion(maintenance.stormModeStatus)
            }, onError: { _ in
                completion(false)
            })
            .disposed(by: disposeBag)
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
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onCompletion()
            }, onError: { _ in
                onCompletion()
            }).disposed(by: disposeBag)
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

}
