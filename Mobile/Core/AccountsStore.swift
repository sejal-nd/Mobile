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
        return accounts[currentIndex]
    }
    
    /// Place current account at the top of the account list
    static func reorderAccountList() -> [Account] {
        let currentAccount = AccountsStore.shared.accounts.remove(at: AccountsStore.shared.currentIndex)
        AccountsStore.shared.accounts.insert(currentAccount, at: 0)
        return AccountsStore.shared.accounts
    }
    
}
