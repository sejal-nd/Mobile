//
//  AccountsStore.swift
//  Mobile
//
//  Created by Marc Shilling on 5/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

final class AccountsStore {
    static let shared = AccountsStore()
    
    var accounts: [Account]!
    var currentAccount: Account!
    var customerIdentifier: String!
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        // Load from disk
        if let customerId = UserDefaults.standard.string(forKey: UserDefaultKeys.customerIdentifier) {
            customerIdentifier = customerId
        }
    }
}
