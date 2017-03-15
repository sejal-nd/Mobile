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
        
        // We should always have a stored username unless user skipped login, in which case this will probably change
        // in a future sprint anyway
        if let storedUsername = fingerprintService.getStoredUsername() {
            username.value = storedUsername
        }
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
    
    func getConfirmPasswordMessage() -> String {
        return "Enter the password for \(username.value.obfuscate()) to enable Touch ID"
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
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }

}
