//
//  SettingsViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class SettingsViewModel {
    
    let disposeBag = DisposeBag()
    
    var username = Variable("")
    var password = Variable("")
    
    private var authService: AuthenticationService?
    private var fingerprintService: FingerprintService?
    
    init(authService: AuthenticationService, fingerprintService: FingerprintService) {
        self.authService = authService
        self.fingerprintService = fingerprintService
        
        username.value = fingerprintService.getStoredUsername()!
    }
    
    func isDeviceTouchIDCompatible() -> Bool {
        return fingerprintService!.isDeviceTouchIDCompatible()
    }
    
    func isTouchIDEnabled() -> Bool {
        return fingerprintService!.isTouchIDEnabled()
    }
    
    func disableTouchID() {
        fingerprintService!.disableTouchID()
    }
    
    func validateCredentials(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        authService!
            .login(username.value, password: password.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { (success: Bool) in
                self.fingerprintService!.setStoredPassword(password: self.password.value)
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

}
