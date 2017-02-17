//
//  FingerprintService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import LocalAuthentication
import SAMKeychain
import SimpleKeychain

class FingerprintService {
    
    func isFingerprintAvailable() -> Bool {
        let context = LAContext()
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        return false
    }
    
    func getStoredUsername() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.StoredTouchIDUsername)
    }
    
    func setStoredUsername(username: String) {
        UserDefaults.standard.set(username, forKey: UserDefaultKeys.StoredTouchIDUsername)
    }
    
    func getStoredPassword() -> String? {
//        return SAMKeychain.password(forService: "FingerprintService", account: "user")
        
        let message = NSLocalizedString("Please enter your fingerprint to sign in", comment: "Prompt TouchID message")
        let keychain = A0SimpleKeychain()
        return keychain.string(forKey: "exelon-pw-2", promptMessage:message)
    }
    
    func setStoredPassword(password: String) {
//        SAMKeychain.setAccessibilityType(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
//        SAMKeychain.setPassword(password, forService: "FingerprintService", account: "user")
        
        let keychain = A0SimpleKeychain()
        keychain.useAccessControl = true
        keychain.defaultAccessiblity = A0SimpleKeychainItemAccessible.whenUnlockedThisDeviceOnly
        keychain.setString(password, forKey:"exelon-pw-2")
    }
    
}
