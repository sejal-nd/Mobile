//
//  KeychainUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 8/31/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

open class KeychainController {
    open var loggingEnabled = false
    
    private init() {}
    
    #warning("audit and refine this.... remove force unwraps ect....")
    private static var _shared: KeychainController?
    public static var shared: KeychainController {
        get {
            if _shared == nil {
                DispatchQueue.global().sync(flags: .barrier) {
                    if _shared == nil {
                        _shared = KeychainController()
                    }
                }
            }
            return _shared!
        }
    }
    
    open subscript(key: String) -> String? {
        get {
            return load(withKey: key)
        } set {
            DispatchQueue.global().sync(flags: .barrier) {
                self.save(newValue, forKey: key)
            }
        }
    }
    
    private func save(_ string: String?, forKey key: String) {
        let query = keychainQuery(withKey: key)
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
    
    private func load(withKey key: String) -> String? {
        let query = keychainQuery(withKey: key)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnAttributes as String)
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)
        
        guard
            let resultsDict = result as? NSDictionary,
            let resultsData = resultsDict.value(forKey: kSecValueData as String) as? Data,
            status == noErr
            else {
                Log.info("Load status: \(status)")
                return nil
        }
        return String(data: resultsData, encoding: .utf8)
    }
    
    private func keychainQuery(withKey key: String) -> NSMutableDictionary {
        let result = NSMutableDictionary()
        result.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        result.setValue(key, forKey: kSecAttrService as String)
        result.setValue(kSecAttrAccessibleAfterFirstUnlock, forKey: kSecAttrAccessible as String)
        return result
    }
}
