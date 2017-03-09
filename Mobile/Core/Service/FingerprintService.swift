//
//  FingerprintService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import LocalAuthentication

class FingerprintService {
    
    final private let KEYCHAIN_KEY = "kExelon_PW"
    
    private let keychain = A0SimpleKeychain()
    
    init() {
        keychain.useAccessControl = true
        keychain.defaultAccessiblity = A0SimpleKeychainItemAccessible.whenPasscodeSetThisDeviceOnly
    }
    
    func isDeviceTouchIDCompatible() -> Bool {
        let context = LAContext()
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        return false
    }
    
    func isTouchIDEnabled() -> Bool {
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.TouchIDEnabled) {
            return true
        }
        return false
    }
    
    func getStoredUsername() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername)
    }
    
    func setStoredUsername(username: String) {
        UserDefaults.standard.set(username, forKey: UserDefaultKeys.LoggedInUsername)
    }
    
    func getStoredPassword() -> String? {
        var promptString = ""
        if let username = getStoredUsername() {
            promptString = NSLocalizedString("Sign in as ", comment: "Touch ID prompt message") + username.obfuscate()
        }
        return keychain.string(forKey: KEYCHAIN_KEY, promptMessage: promptString)
    }
    
    func setStoredPassword(password: String) {
        keychain.setString(password, forKey: KEYCHAIN_KEY)
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.TouchIDEnabled)
    }
    
    func disableTouchID() {
        keychain.deleteEntry(forKey: KEYCHAIN_KEY)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.TouchIDEnabled)
    }
    
}
