//
//  SharedWebCredentialService.swift
//  BGE
//
//  Created by Joseph Erlandson on 6/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import Security

public enum SharedWebCredentials {
    
    public typealias Credential = (account: String, password: String)
    
    public static func request(domain: String?, completion: @escaping (Credential?, Error?) -> Void) {
        SecRequestSharedWebCredential(domain as CFString?, nil) { webCredentials, requestError in
            var error: Error? = nil
            var credential: Credential? = nil
            
            defer {
                completion(credential, error)
            }
            
            guard requestError == nil else {
                let errorIsNoCredentialsFound = CFErrorGetDomain(requestError) as String == NSOSStatusErrorDomain && CFErrorGetCode(requestError) == Int(errSecItemNotFound)
                
                if !errorIsNoCredentialsFound { // No credentals found shouldn't be treated as an error
                    error = requestError
                }
                
                return
            }
            
            guard let webCredentials = webCredentials , CFArrayGetCount(webCredentials) > 0 else {
                // User probably pressed "not now"
                return
            }
            
            // Casting bonanza!!
            let unsafeCredential = CFArrayGetValueAtIndex(webCredentials, 0)
            let credentialDictionary = unsafeBitCast(unsafeCredential, to: CFDictionary.self)
            
            let unsafeAccount = CFDictionaryGetValue(credentialDictionary, Unmanaged.passUnretained(kSecAttrAccount).toOpaque())
            let account = unsafeBitCast(unsafeAccount, to: CFString.self) as String
            
            let unsafePassword = CFDictionaryGetValue(credentialDictionary, Unmanaged.passUnretained(kSecSharedPassword).toOpaque())
            let password = unsafeBitCast(unsafePassword, to: CFString.self) as String
            
            credential = (account, password)
        }
    }
    
    public static func save(credential: Credential, domain: String, completion: @escaping (Error?) -> Void) {
        SecAddSharedWebCredential(domain as CFString, credential.account as CFString, credential.password as CFString?) { error in
            completion(error)
        }
    }
    
    public static func delete(account: String, domain: String, completion: @escaping (Error?) -> Void) {
        SecAddSharedWebCredential(domain as CFString, account as CFString, nil) { error in
            completion(error)
        }
    }
    
    public static func generatePassword() -> String? {
        return SecCreateSharedWebCredentialPassword() as String?
    }
    
}
