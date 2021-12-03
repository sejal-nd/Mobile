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
    
    let moveServiceWebURL: URL? = {
        switch Configuration.shared.opco {
        case .ace, .comEd, .delmarva, .peco, .pepco:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/CustomerServices/service/move?utm_source=MoveLink&utm_medium=MobileApp&utm_id=SSMRedirect")
        default:
            return nil
        }
    }()
    
    let stopServiceWebURL: URL? = {
        switch Configuration.shared.opco {
        case .ace, .comEd, .delmarva, .peco, .pepco:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/accounts/login?TARGET=%2FCustomerServices%2Fservice%2Fstop&utm_source=StopLink&utm_medium=MobileApp&utm_campaign=SSMRedirect")
        default:
            return nil
        }
    }()
    
    let startServiceWebURL: URL? = {
        switch Configuration.shared.opco {
        case .bge:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/CustomerServices/service/start?referrer=mobileapp")
        case .ace, .comEd, .delmarva, .peco, .pepco:
            return URL(string: "https://\(Configuration.shared.associatedDomain)/CustomerServices/service/start?utm_source=StartLink&utm_medium=MobileApp&utm_id=SSMRedirect")
        default:
            return nil
        }
    }()
}
