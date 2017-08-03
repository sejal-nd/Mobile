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
    
    private var authService: AuthenticationService
    private var fingerprintService: FingerprintService
    private var accountService: AccountService
    
    init(authService: AuthenticationService, fingerprintService: FingerprintService, accountService: AccountService) {
        self.authService = authService
        self.fingerprintService = fingerprintService
        self.accountService = accountService
        
        // We should always have a stored username unless user skipped login, in which case this will probably change
        // in a future sprint anyway
        if let storedUsername = fingerprintService.getStoredUsername() {
            username.value = storedUsername
        }
    }
    
    func isDeviceTouchIDCompatible() -> Bool {
        return fingerprintService.isDeviceTouchIDCompatible()
    }
    
    func isTouchIDEnabled() -> Bool {
        return fingerprintService.isTouchIDEnabled()
    }
    
    func disableTouchID() {
        fingerprintService.disableTouchID()
    }
    
    func getConfirmPasswordMessage() -> String {
        return String(format: NSLocalizedString("Enter the password for %@ to enable Touch ID", comment: ""), username.value)
    }
    
    func fetchAccounts() -> Observable<[Account]> {
        return accountService.fetchAccounts()
    }
    
    func validateCredentials(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        authService.validateLogin(username.value, password: password.value).observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { _ in
                self.fingerprintService.setStoredPassword(password: self.password.value)
                onSuccess()
            }, onError: { (error: Error) in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }

}
