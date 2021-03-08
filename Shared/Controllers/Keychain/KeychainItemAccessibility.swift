//
//  KeychainItemAccessibility.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 2/22/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

public enum KeychainItemAccessibility {
  case afterFirstUnlock // The default case.
  case afterFirstUnlockThisDeviceOnly
  case whenPasscodeSetThisDeviceOnly
  case whenUnlocked
  case whenUnlockedThisDeviceOnly
  
    var value: String {
        switch self {
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock as String
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked as String
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        }
    }
}
