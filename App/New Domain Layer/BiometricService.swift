//
//  BiometricService.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import LocalAuthentication

enum BiometricService {
    
    private static let keychainKey = "kExelon_PW"
    
    private static var keychain: A0SimpleKeychain {
        let keychain = A0SimpleKeychain()
        keychain.useAccessControl = true
        keychain.defaultAccessiblity = A0SimpleKeychainItemAccessible.whenPasscodeSetThisDeviceOnly
        
        /* We use the following to detect a user who restored from backup onto a new device. In that case,
         * the UserDefaults would have persisted, but the keychain where the password was stored would have been wiped.
         * That puts us in a bad position where we think Biometrics are enabled but it actually isn't. So we use this method
         * of storing a file with the isExcludedFromBackup attribute, and reset the relevant UserDefaults when the file
         * does not exist. */
        let manager = FileManager.default
        var fileUrl = manager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("FirstLaunchOnNewDevice")
        if !manager.fileExists(atPath: fileUrl.path) {
            disableBiometrics()
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.shouldPromptToEnableBiometrics)
            
            manager.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil)
            
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            do {
                try fileUrl.setResourceValues(resourceValues)
            } catch let error {
                dLog("Failed to set resource values: \(error.localizedDescription)")
            }
        }
        
        return keychain
    }
    
    static func deviceBiometryType() -> String? {
        let context = LAContext()
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID {
                return "Face ID"
            } else if context.biometryType == .touchID {
                return "Touch ID"
            }
        }
        return nil
    }
    
    static func isBiometricsEnabled() -> Bool {
        return deviceBiometryType() != nil && UserDefaults.standard.bool(forKey: UserDefaultKeys.isBiometricsEnabled)
    }
    
    static func getStoredUsername() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
    }
    
    static func setStoredUsername(username: String) {
        UserDefaults.standard.set(username, forKey: UserDefaultKeys.loggedInUsername)
    }
    
    static func getStoredPassword() -> String? {
        var promptString = ""
        if let username = getStoredUsername() {
            promptString = String(format: NSLocalizedString("Sign in as %@", comment: ""), username)
        }
        return keychain.string(forKey: keychainKey, promptMessage: promptString)
    }
    
    static func setStoredPassword(password: String) {
        keychain.setString(password, forKey: keychainKey)
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.isBiometricsEnabled)
    }
    
    static func disableBiometrics() {
        keychain.deleteEntry(forKey: keychainKey)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.isBiometricsEnabled)
    }
    
}
