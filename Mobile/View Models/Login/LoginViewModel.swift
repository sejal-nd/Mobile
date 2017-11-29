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
    
    var accountDetail: AccountDetail?
    
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
        return UserDefaults.standard.bool(forKey: UserDefaultKeys.ShouldPromptToEnableBiometrics)
    }
    
    func setShouldPromptToEnableBiometrics(_ prompt: Bool) {
        UserDefaults.standard.set(prompt, forKey: UserDefaultKeys.ShouldPromptToEnableBiometrics)
    }
    
    func performLogin(onSuccess: @escaping (Bool) -> Void, onRegistrationNotComplete: @escaping () -> Void, onError: @escaping (String?, String) -> Void) {
        if username.value.isEmpty || password.value.isEmpty {
            onError(nil, "Please enter your username and password")
            return;
        }
        
        isLoggingIn = true
        authService.login(username.value, password: password.value, stayLoggedIn:keepMeSignedIn.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { [weak self] (responseTuple: (ProfileStatus, AccountDetail)) in
                guard let `self` = self else { return }
                self.isLoggingIn = false
                self.accountDetail = responseTuple.1
                onSuccess(responseTuple.0.tempPassword)
                if responseTuple.0.tempPassword {
                    self.authService.logout().subscribe(onError: { (error) in
                        dLog("Logout Error: \(error)")
                    }).disposed(by: self.disposeBag)
                }
            }, onError: { [weak self] error in
                self?.isLoggingIn = false
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnAccountProtected.rawValue {
                    onError(NSLocalizedString("Password Protected Account", comment: ""), serviceError.localizedDescription)
                } else if serviceError.serviceCode == ServiceErrorCode.FnAcctNotActivated.rawValue {
                    onRegistrationNotComplete()
                } else {
                    onError(nil, error.localizedDescription)
                }
                Analytics().logScreenView(AnalyticsPageView.LoginError.rawValue,
                                          dimensionIndex: Dimensions.ErrorCode,
                                          dimensionValue: serviceError.serviceCode)
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
    
    func attemptLoginWithBiometrics(onLoad: @escaping () -> Void, onDidNotLoad: @escaping () -> Void, onSuccess: @escaping (Bool) -> Void, onError: @escaping (String?, String) -> Void) {
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
    
    func checkForMaintenance(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenanceInfo in
                onSuccess(maintenanceInfo.allStatus)
            }, onError: { error in
                onError(error.localizedDescription)
            }).disposed(by: disposeBag)
    }
    
    func validateRegistration(guid: String, onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        registrationService.validateConfirmationEmail(guid)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { err in
                let serviceError = err as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnProfNotFound.rawValue {
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
