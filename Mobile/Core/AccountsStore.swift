//
//  AccountsStore.swift
//  Mobile
//
//  Created by Marc Shilling on 5/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

// Used for WatchOS
protocol AccountStoreChangedDelegate {
    func newAccountUpdate(_ account: Account)
    
    func currentAccountDidUpdate(_ account: Account)
}

final class AccountsStore {
    static let shared = AccountsStore()
    
    var accounts: [Account]!
    var currentAccount: Account! {
        didSet {
            if currentAccount == nil {
                
                
                return
            }
            
            if oldValue != nil {
                
                accountStoreChangedDelegate?.currentAccountDidUpdate(currentAccount)
            } else {
                
                accountStoreChangedDelegate?.newAccountUpdate(currentAccount)
            }
        }
    }
    var customerIdentifier: String!
    
    public var accountStoreChangedDelegate: AccountStoreChangedDelegate?

    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        // Load from disk
        if let customerId = UserDefaults.standard.string(forKey: UserDefaultKeys.customerIdentifier) {
            customerIdentifier = customerId
        }
    }
}
