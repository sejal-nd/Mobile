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
    
    private var authService: AuthenticationService?
    private var fingerprintService: FingerprintService?
    
    init(authService: AuthenticationService, fingerprintService: FingerprintService) {
        self.authService = authService
        self.fingerprintService = fingerprintService
    }
    
    func isDeviceTouchIDEnabled() -> Bool {
        return fingerprintService!.isFingerprintAvailable()
    }
    
    func didLoginWithDifferentAccountThanStoredInKeychain() -> Bool {
        if let username = fingerprintService!.getStoredUsername() {
            if self.username.value != username {
                return true
            }
        }
        return false
    }
    
    func performLogin(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        authService!
            .login(username.value, password: password.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { (success: Bool) in
                onSuccess()
            }, onError: { (error: Error) in
                var errorString = ""
                switch(error as! ServiceError) {
                case ServiceError.JSONParsing:
                    errorString = "JSONParsing Error"
                    break
                case ServiceError.Custom(let code, let description):
                    errorString = description
                    break
                case ServiceError.Other(let error):
                    errorString = error.localizedDescription
                    break
                }
                onError(errorString)
            })
            .addDisposableTo(disposeBag)
    }
    
    func storeCredentialsInTouchIDKeychain() {
        fingerprintService!.setStoredUsername(username: username.value)
        fingerprintService!.setStoredPassword(password: password.value)
    }
    
    func attemptLoginWithTouchID(onLoad: @escaping () -> Void, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        if let username = fingerprintService!.getStoredUsername() {
            self.username.value = username
            if let password = fingerprintService!.getStoredPassword() {
                self.password.value = password
                onLoad()
                performLogin(onSuccess: onSuccess, onError: onError)
            } else { // Cancelled Touch ID dialog
                self.username.value = ""
                self.password.value = ""
            }
        }
    }
    

}
