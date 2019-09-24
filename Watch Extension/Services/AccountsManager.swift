//
//  AccountsManager.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit
import RxSwift

struct AccountsManager {
    
    private let disposeBag = DisposeBag()

    public func fetchAccounts(success: @escaping ([Account]) -> Void, error: @escaping (ServiceError) -> Void) {
        dLog("Fetching Accounts...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil else {
            dLog("Could not find auth token in Accounts Manager Fetch Accounts.")
            error(Errors.noAuthTokenFound)
            return
        }
        
        let accountService = MCSAccountService()
        accountService.fetchAccounts().subscribe(onNext: { accounts in
            // handle success
            guard let firstAccount = AccountsStore.shared.accounts.first else {
                dLog("Could not retrieve first account in account list.")
                return
            }
            
            if AccountsStore.shared.currentIndex == nil {
                AccountsStore.shared.currentIndex = 0
            }
            
            NotificationCenter.default.post(name: Notification.Name.defaultAccountSet, object: firstAccount)
            
            dLog("Accounts Fetched.")
            
            success(accounts)
        }, onError: { accountsError in
            // handle error
            dLog("Failed to retrieve accounts: \(accountsError.localizedDescription)")
            let serviceError = (accountsError as? ServiceError) ?? ServiceError(serviceCode: accountsError.localizedDescription, serviceMessage: nil, cause: nil)
            error(serviceError)
        })
            .disposed(by: disposeBag)
    }
    
}
