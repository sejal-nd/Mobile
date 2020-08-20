//
//  AccountsStore.swift
//  Mobile
//
//  Created by Marc Shilling on 5/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

final class AccountsStore {
    static let shared = AccountsStore()
    
    var accounts: [Account]!
    var currentIndex: Int!
    var customerIdentifier: String!
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        // Load from disk
        guard let customerId = UserDefaults.standard.string(forKey: UserDefaultKeys.customerIdentifier) else { return }
        customerIdentifier = customerId
    }
    
    var currentAccount: Account {
        let currentAccount = accounts[currentIndex]
        return currentAccount
    }
}
