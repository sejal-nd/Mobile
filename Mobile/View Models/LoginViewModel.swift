//
//  LoginViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class LoginViewModel {
    
    let disposeBag = DisposeBag()
    
    var username = Variable("")
    var password = Variable("")
    var keepMeSignedIn = Variable(false)
    
    private var authService: AuthenticationService
    private var fingerprintService: FingerprintService
    
    init(authService: AuthenticationService, fingerprintService: FingerprintService) {
        self.authService = authService
        self.fingerprintService = fingerprintService
        
        if let username = fingerprintService.getStoredUsername() {
            self.username.value = username
        }
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
    
    func performLogin(onSuccess: @escaping () -> Void, onError: @escaping (String?, String) -> Void) {
        print("Keep me signed in = \(keepMeSignedIn.value)") // TODO: Something with this
        
        if username.value.isEmpty || password.value.isEmpty {
            onError(nil, "Please enter your username and password")
            return;
        }
        
        authService.login(username.value, password: password.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnAccountProtected.rawValue {
                    onError(NSLocalizedString("Password Protected Account", comment: ""), serviceError.localizedDescription)
                } else {
                    onError(nil, error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
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
    
    func attemptLoginWithTouchID(onLoad: @escaping () -> Void, onSuccess: @escaping () -> Void, onError: @escaping (String?, String) -> Void) {
        if let username = fingerprintService.getStoredUsername() {
            if let password = fingerprintService.getStoredPassword() {
                self.username.value = username
                self.password.value = password
                onLoad()
                performLogin(onSuccess: onSuccess, onError: onError)
            }
        }
    }
    
    func disableTouchID() {
        fingerprintService.disableTouchID()
    }
    
    func isTouchIDEnabled() -> Bool {
        return fingerprintService.isTouchIDEnabled()
    }
    
}
