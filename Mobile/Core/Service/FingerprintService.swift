//
//  FingerprintService.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import LocalAuthentication
import SimpleKeychain

class FingerprintService {
    
    final private let KEYCHAIN_KEY = "kExelon_PW"
    
    private let keychain = A0SimpleKeychain()
    
    init() {
        keychain.useAccessControl = true
        keychain.defaultAccessiblity = A0SimpleKeychainItemAccessible.whenPasscodeSetThisDeviceOnly
    }
    
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
        var promptString = ""
        if let username = getStoredUsername() {
            let startIndex = username.index(username.startIndex, offsetBy: 6)
            let hiddenUsername = username.replacingCharacters(in: startIndex..<username.endIndex, with: "**********")
            promptString = NSLocalizedString("Sign in as ", comment: "Touch ID prompt message") + hiddenUsername
        }
        return keychain.string(forKey: KEYCHAIN_KEY, promptMessage: promptString)
    }
    
    func setStoredPassword(password: String) {
        keychain.setString(password, forKey: KEYCHAIN_KEY)
    }
    
}
