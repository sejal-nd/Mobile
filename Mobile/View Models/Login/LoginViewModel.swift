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
    var touchIDAutofilledPassword: String? = nil
    var keepMeSignedIn = Variable(false)
    var touchIdEnabled = Variable(false)
    
    private var authService: AuthenticationService
    private var fingerprintService: FingerprintService
    private var registrationService: RegistrationService
    
    init(authService: AuthenticationService, fingerprintService: FingerprintService, registrationService: RegistrationService) {
        self.authService = authService
        self.fingerprintService = fingerprintService
        self.registrationService = registrationService
        
        if let username = fingerprintService.getStoredUsername() {
            self.username.value = username
        }
        touchIdEnabled.value = fingerprintService.isTouchIDEnabled()
    }
    
    func isDeviceTouchIDCompatible() -> Bool {
        return fingerprintService.isDeviceTouchIDCompatible()
    }
        
    func shouldPromptToEnableTouchID() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultKeys.ShouldPromptToEnableTouchID)
    }
    
    func setShouldPromptToEnableTouchID(_ prompt: Bool) {
        UserDefaults.standard.set(prompt, forKey: UserDefaultKeys.ShouldPromptToEnableTouchID)
    }
    
    func performLogin(onSuccess: @escaping (Bool) -> Void, onRegistrationNotComplete: @escaping () -> Void, onError: @escaping (String?, String) -> Void) {
        if username.value.isEmpty || password.value.isEmpty {
            onError(nil, "Please enter your username and password")
            return;
        }
        
        authService.login(username.value, password: password.value, stayLoggedIn:keepMeSignedIn.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { (profileStatus: ProfileStatus) in
                onSuccess(profileStatus.tempPassword)
                if profileStatus.tempPassword {
                    self.authService.logout().subscribe(onNext: {
                    }, onError: { (error) in
                        print("Logout Error: \(error)")
                    }).disposed(by: self.disposeBag)
                }
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnAccountProtected.rawValue {
                    onError(NSLocalizedString("Password Protected Account", comment: ""), serviceError.localizedDescription)
                } else if serviceError.serviceCode == ServiceErrorCode.FnAcctNotActivated.rawValue {
                    onRegistrationNotComplete()
                } else {
                    onError(nil, error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func getStoredUsername() -> String? {
        return fingerprintService.getStoredUsername()
    }
    
    func storeUsername() {
        fingerprintService.setStoredUsername(username: username.value)
    }
    
    func storePasswordInTouchIDKeychain() {
        fingerprintService.setStoredPassword(password: password.value)
    }
    
    func attemptLoginWithTouchID(onLoad: @escaping () -> Void, onSuccess: @escaping (Bool) -> Void, onError: @escaping (String?, String) -> Void) {
        if let username = fingerprintService.getStoredUsername() {
            if let password = fingerprintService.getStoredPassword() {
                self.username.value = username
                self.touchIDAutofilledPassword = password
                self.password.value = password
                onLoad()
                performLogin(onSuccess: onSuccess, onRegistrationNotComplete: {}, onError: onError)
            }
        }
    }
    
    func disableTouchID() {
        fingerprintService.disableTouchID()
        touchIdEnabled.value = false
    }
    
    func checkForMaintenance(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        var isMaintenanceMode = false
        
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenanceInfo in
                isMaintenanceMode = maintenanceInfo.allStatus
                onSuccess(isMaintenanceMode)
            }, onError: { error in
                _ = error as! ServiceError
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
