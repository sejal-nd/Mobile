//
//  KeychainUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 8/31/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

open class KeychainController {
    private init() { }
    
    static let `default` = KeychainController()
    
    func set(_ value: String,
             forKey key: KeychainController.Key,
             withAccessibility accessibility: KeychainItemAccessibility = .afterFirstUnlock) {
        save(value, forKey: key.rawValue, accessibility: accessibility)
    }
    
    func string(forKey key: KeychainController.Key,
                withAccessibility accessibility: KeychainItemAccessibility = .afterFirstUnlock) -> String? {
        return load(forKey: key.rawValue, accessibility: accessibility)
    }
    
    func remove(forKey key: KeychainController.Key,
                withAccessibility accessibility: KeychainItemAccessibility = .afterFirstUnlock) {
        save(nil, forKey: key.rawValue, accessibility: accessibility)
    }
}

// MARK: Private API

extension KeychainController {
    private func save(_ string: String?, forKey key: String, accessibility: KeychainItemAccessibility) {
        let query = keychainQuery(forKey: key, accessibility: accessibility)
        let objectData: Data? = string?.data(using: .utf8, allowLossyConversion: false)
        
        if SecItemCopyMatching(query, nil) == noErr {
            if let dictData = objectData {
                let status = SecItemUpdate(query, NSDictionary(dictionary: [kSecValueData: dictData]))
                Log.info("Update status: \(status)")
            } else {
                let status = SecItemDelete(query)
                Log.info("Delete status: \(status)")
            }
        } else {
            if let dictData = objectData {
                query.setValue(dictData, forKey: kSecValueData as String)
                let status = SecItemAdd(query, nil)
                Log.info("Update status: \(status)")
            }
        }
    }
    
    private func load(forKey key: String, accessibility: KeychainItemAccessibility) -> String? {
        let query = keychainQuery(forKey: key, accessibility: accessibility)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnAttributes as String)
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)
        
        guard let resultsDict = result as? NSDictionary,
              let resultsData = resultsDict.value(forKey: kSecValueData as String) as? Data,
              status == noErr else {
            Log.error("Load status: \(status)")
            return nil
        }
        return String(data: resultsData, encoding: .utf8)
    }
    
    private func keychainQuery(forKey key: String, accessibility: KeychainItemAccessibility) -> NSMutableDictionary {
        let result = NSMutableDictionary()
        result.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        result.setValue(key, forKey: kSecAttrService as String)
        result.setValue(accessibility.value, forKey: kSecAttrAccessible as String)
        return result
    }
}
