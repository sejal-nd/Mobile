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
        
    init() {
        
        // We should always have a stored username unless user skipped login, in which case this will probably change
        // in a future sprint anyway
        if let storedUsername = BiometricService.getStoredUsername() {
            username.accept(storedUsername)
        }
    }
    
    func isDeviceBiometricCompatible() -> Bool {
        return BiometricService.deviceBiometryType() != nil
    }
    
    func biometricsString() -> String? {
        return BiometricService.deviceBiometryType()
    }
    
    func isBiometryEnabled() -> Bool {
        return BiometricService.isBiometricsEnabled()
    }
    
    func disableBiometrics() {
        BiometricService.disableBiometrics()
    }
    
    func getConfirmPasswordMessage() -> String {
        return String(format: NSLocalizedString("Enter the password for %@ to enable \(BiometricService.deviceBiometryType()!)", comment: ""), username.value)
    }
    
    func fetchAccounts() -> Observable<[Account]> {
        return AccountService.rx.fetchAccounts()
    }
    
    func validateCredentials(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        AuthenticationService.validateLogin(username: username.value,
                                           password: password.value) { [weak self] result in
                                            switch result {
                                            case .success:
                                                guard let self = self else { return }
                                                BiometricService.setStoredPassword(password: self.password.value)
                                                onSuccess()
                                            case .failure(let error):
                                                onError(error.description)
                                            }
        }
    }
    
    let billingVideosUrl: URL? = {
        return URL(string: FeatureFlagUtility.shared.string(forKey: .billingVideoURL))
    }()
    
}
