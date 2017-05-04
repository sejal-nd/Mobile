//
//  AccountsStore.swift
//  Mobile
//
//  Created by Marc Shilling on 5/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

final class AccountsStore {
    static let sharedInstance = AccountsStore()
    
    var accounts: [Account]!
    var currentAccount: Account!
    
    // Private init protects against another instance being accidentally instantiated
    private init() { }
}
