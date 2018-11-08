//
//  AccountsManager.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit
import RxSwift

class AccountsManager {
    
    private let disposeBag = DisposeBag()
    
    public func fetchAccounts(success: @escaping ([Account]) -> Void) {
        aLog("Fetching Accounts...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil else {
            aLog("Could not find auth token in Accounts Manager Fetch Accounts.")
            return
        }
        
        let accountService = MCSAccountService()
        accountService.fetchAccounts().subscribe(onNext: { accounts in
            // handle success
            guard let firstAccount = AccountsStore.shared.accounts.first else {
                aLog("Could not retrieve first account in account list.")
                return
            }
            
            if AccountsStore.shared.getSelectedAccount() == nil {
                AccountsStore.shared.setSelectedAccount(firstAccount)
            }
            
            aLog("Accounts Fetched.")
            
            success(accounts)
        }, onError: { error in
            // handle error
            aLog("Failed to retrieve accounts: \(error.localizedDescription)")
        })
            .disposed(by: disposeBag)
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
        accountService.fetchAccountDetail(account: currentAccount, getPayments: true, getBudgetBilling: false)
            .subscribe(onNext: { accountDetail in
                // handle success
                aLog("Account Details Fetched.")
                
                success(accountDetail)
            }, onError: { accountDetailError in
                // handle error
                aLog("Failed to Fetch Account Details. \(accountDetailError.localizedDescription)")
                let serviceError = (accountDetailError as? ServiceError) ?? ServiceError(serviceCode: accountDetailError.localizedDescription, serviceMessage: nil, cause: nil)
                
                error(serviceError)
            })
            .disposed(by: disposeBag)
    }
    
}
