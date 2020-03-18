//
//  UserSession.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/18/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

class UserSession {
//    enum State {
//        case loggedIn
//        case loggedOut
//    }
//
//    var state: State {
//        if token.isEmpty {
//            return .loggedOut
//        } else {
//            return .loggedIn
//        }
//    }
    
    static let shared = UserSession()
    
    private init() {
        
        // todo fetch keep me signed in stuff
    }


    
    var token = ""
    
    
    // may want to live somewhere else.
    
//    var account: Account?
//    
//    var details: AccountDetail?
//    
//    var accounts = [Account]()
    
    
    
    
//    var accounts: [Account]!
//    var currentIndex: Int!
//    var customerIdentifier: String!
//
//    // Private init protects against another instance being accidentally instantiated
//    private init() {
//        // Load from disk
//        guard let customerId = UserDefaults.standard.string(forKey: UserDefaultKeys.customerIdentifier) else { return }
//        customerIdentifier = customerId
//    }
//
//    var currentAccount: Account {
//        let currentAccount = accounts[currentIndex]
//        return currentAccount
//    }
    
}
