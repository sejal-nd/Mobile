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
    
    private static let keychain = KeychainController.default
    
    enum BiometricError: Error{
        case noBiometrics
        case failedToAuthenticate
        
        var title: String {
            switch self {
            case .noBiometrics:
                return "Biometrics Are Not Enabled"
            case .failedToAuthenticate:
                return "Failed to Authenticate"
            }
        }
        
        var description: String {
            switch self {
            case .noBiometrics:
                return "Please enable biometrics on your device to use this feature"
            case .failedToAuthenticate:
                return "Please make sure you are using the biometrics set up with this device"
            }
        }
    }
    

    
    static func disableBiometricsOnFreshInstall() {
        let manager = FileManager.default
        if var fileUrl = manager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("FirstLaunchOnNewDevice"),
            !manager.fileExists(atPath: fileUrl.path) {
            disableBiometrics()
            UserDefaults.standard.set(true, forKey: UserDefaultKeys.shouldPromptToEnableBiometrics)
            
            manager.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil)
            
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            do {
                try fileUrl.setResourceValues(resourceValues)
            } catch let error {
                Log.info("Failed to set resource values: \(error.localizedDescription)")
            }
        }
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
    
    static func getStoredPassword(completion: @escaping (Result<String?, BiometricError>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Autofill Password"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        let password = keychain.get(.keychainKey)
                        completion(.success(password))
                    } else {
                        Log.error("Authentication error: \(String(describing: authenticationError))/n\(String(describing: authenticationError?.localizedDescription))")
                        completion(.failure(.failedToAuthenticate))
                    }
                }
            }
        } else {
            Log.info("Biometrics not enabled")
            completion(.failure(.noBiometrics))
        }
    }
    
    static func setStoredPassword(password: String) {
        keychain.set(password, forKey: .keychainKey)
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.isBiometricsEnabled)
    }
    
    static func disableBiometrics() {
        keychain.delete(.keychainKey)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.isBiometricsEnabled)
    }
    
}
