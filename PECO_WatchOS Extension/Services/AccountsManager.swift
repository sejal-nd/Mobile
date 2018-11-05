//
//  AccountsManager.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class AccountsManager {
    
    public func fetchAccounts(success: @escaping ([Account]) -> Void) {
        aLog("Fetching Accounts...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil else {
            aLog("Could not find auth token in Accounts Manager Fetch Accounts.")
            return
        }
        
        let accountService = MCSAccountService()
        
        // todo Rxswiftify
//        accountService.fetchAccounts { serviceResult in
//            switch serviceResult {
//            case .success(let accounts):
//                guard let firstAccount = AccountsStore.shared.accounts.first else {
//                    aLog("Could not retrieve first account in account list.")
//                    return
//                }
//                
//                if AccountsStore.shared.getSelectedAccount() == nil {
//                    AccountsStore.shared.setSelectedAccount(firstAccount)
//                }
//                
//                aLog("Accounts Fetched.")
//                
//                success(accounts)
//            case .failure(let serviceError):
//                aLog("Failed to retrieve accounts: \(serviceError.localizedDescription)")
//            }
//        }
    }
    
    // Fetch Account Details: We need this to determine if the current account is password protected.
    public func fetchAccountDetails(success: @escaping (AccountDetail) -> Void, noAuthToken: @escaping (ServiceError) -> Void, error: @escaping (ServiceError) -> Void) {
        aLog("Fetching Account Details...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil, let currentAccount = AccountsStore.shared.getSelectedAccount() else {
            aLog("Could not find auth token in Accounts Manager Fetch Account Details.")
            noAuthToken(Errors.noAuthTokenFound)
            return
        }
        
        
        let accountService = MCSAccountService()
        // todo: rxswiftity
//        accountService.fetchAccountDetail(account: currentAccount) { serviceResult in
//            DispatchQueue.main.async {
//                switch serviceResult {
//                case .success(let accountDetail):
//                    aLog("Account Details Fetched.")
//                    
//                    success(accountDetail)
//                case .failure(let serviceError):
//                    aLog("Failed to Fetch Account Details. \(serviceError.localizedDescription)")
//                    
//                    error(serviceError)
//                }
//            }
//        }
    }
    
}
