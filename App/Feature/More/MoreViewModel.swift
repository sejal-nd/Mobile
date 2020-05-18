//
//  MoreViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class MoreViewModel {
    
    let disposeBag = DisposeBag()
    
    var username = BehaviorRelay(value: "")
    var password = BehaviorRelay(value: "")
    
    private var authService: AuthenticationService
    private var biometricsService: BiometricsService
    private var accountService: AccountService
    
    init(authService: AuthenticationService, biometricsService: BiometricsService, accountService: AccountService) {
        self.authService = authService
        self.biometricsService = biometricsService
        self.accountService = accountService
        
        // We should always have a stored username unless user skipped login, in which case this will probably change
        // in a future sprint anyway
        if let storedUsername = biometricsService.getStoredUsername() {
            username.accept(storedUsername)
        }
    }
    
    func isDeviceBiometricCompatible() -> Bool {
        return biometricsService.deviceBiometryType() != nil
    }
    
    func biometricsString() -> String? {
        return biometricsService.deviceBiometryType()
    }
    
    func isBiometryEnabled() -> Bool {
        return biometricsService.isBiometricsEnabled()
    }
    
    func disableBiometrics() {
        biometricsService.disableBiometrics()
    }
    
    func getConfirmPasswordMessage() -> String {
        return String(format: NSLocalizedString("Enter the password for %@ to enable \(biometricsService.deviceBiometryType()!)", comment: ""), username.value)
    }
    
    func fetchAccounts() -> Observable<[Account]> {
        return accountService.fetchAccounts()
    }
    
    func validateCredentials(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        authService.validateLogin(username: username.value, password: password.value).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.biometricsService.setStoredPassword(password: self.password.value)
                onSuccess()
                }, onError: { (error: Error) in
                    onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    let billingVideosUrl: URL? = {
        return URL(string: RemoteConfigUtility.shared.string(forKey: .billingVideoURL))!
    }()
    
}
