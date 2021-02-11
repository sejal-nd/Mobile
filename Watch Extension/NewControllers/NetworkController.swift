//
//  NetworkController.swift
//  EUMobile-Watch Extension
//
//  Created by Joseph Erlandson on 2/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import SwiftUI

class NetworkController: ObservableObject {
    @Published var isLoggedIn = false    
    @Published var accountListState: AccountListState = .loading
    @Published var outageState: OutageState = .loading
    @Published var usageState: UsageState = .loading
    //    @Published var bill: WatchBill
    
    init() {
        setLoginStatus()
        fetchData()
        
        WatchSessionController.shared.authTokenDidUpdate = { [weak self] () -> Void in
            self?.setLoginStatus()
            self?.fetchData()
        }
    }
}

// MARK: Network Requests

extension NetworkController {
    private func fetchAccounts(completion: @escaping (Result<Void, Error>) -> Void) {
        AccountService.fetchAccounts { [weak self] networkResult in
            switch networkResult {
            case .success(let accounts):
                if AccountsStore.shared.currentIndex == nil {
                    AccountsStore.shared.currentIndex = 0
                }
                
                let watchAccounts = accounts.map({ WatchAccount(account: $0) })
                self?.accountListState = .loaded(accounts: watchAccounts)
                completion(.success(()))
            case .failure(let error):
                if error == .passwordProtected {
                    Log.error("Failed to retrieve account list.  Password Protected Account.")
                    
                    self?.accountListState = .error(errorState: .passwordProtected)
                } else {
                    Log.error("Failed to retrieve account list: \(error.localizedDescription)")
                    
                    self?.accountListState = .error(errorState: .other)
                }
                completion(.failure(error))
            }
        }
    }
    
    private func setLoginStatus() {
        let authToken = KeychainManager.shared[keychainKeys.authToken]
        isLoggedIn = authToken != nil
    }
    
    private func fetchData() {
        guard isLoggedIn else {
            Log.warning("User is not logged in.")
            return
        }
        
        fetchAccounts { [weak self] result in
            switch result {
            case .success:
                self?.fetchFeatureData()
            case .failure:
                break
            }
        }
    }
    
    func fetchFeatureData() {
        setLoginStatus()
        
        accountListState = .loading
        outageState = .loading
        usageState = .loading
        #warning("todo")
        // billingState = .loading
        
        Log.info("Fetching Maintenance Mode Status...")
        
        guard KeychainManager.shared[keychainKeys.authToken] != nil,
              let _ = AccountsStore.shared.currentIndex else {
            Log.error("Could not find auth token in Accounts Manager Fetch Account Details.")
            
            setLoginStatus()
            return
        }
        
        // MARK: Maintenance Mode
        AnonymousService.maintenanceMode { [weak self] networkResult in
            switch networkResult {
            case .success(let maintenanceMode):
                Log.info("Maintenance Mode Fetched.")
                
                guard !maintenanceMode.all else {
                    Log.warning("Maintenance mode active: ALL.")
                    
                    self?.outageState = .error(errorState: .maintenanceMode)
                    self?.usageState = .error(errorState: .maintenanceMode)
                    #warning("bill state goes here")
                    //                        self?.billState = .error(errorState: .maintenanceMode)
                    return
                }
                
                // MARK: Account Details
                AccountService.fetchAccountDetails { [weak self] networkResult in
                    switch networkResult {
                    case .success(let accountDetail):
                        Log.info("Account Details Fetched.")
                        
                        guard !accountDetail.isPasswordProtected else {
                            Log.warning("Password protected account.")
                            
                            self?.outageState = .error(errorState: .passwordProtected)
                            self?.usageState = .error(errorState: .passwordProtected)
                            #warning("bill state goes here")
                            //                        self?.billState = .error(errorState: .passwordProtected)
                            return
                        }
                        
                        let account = WatchAccount(account: AccountsStore.shared.currentAccount)
                        
                        if !maintenanceMode.outage {
                            // MARK: Outage
                            OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { [weak self] networkResult in
                                switch networkResult {
                                case .success(let outageStatus):
                                    Log.info("Outage Status Fetched.")
                                    
                                    let watchOutage = WatchOutage(outageStatus: outageStatus)
                                    self?.outageState = .loaded(outage: watchOutage,
                                                                account: account)
                                case .failure(let error):
                                    Log.error("Failed to retrieve outage status: \(error.localizedDescription)")
                                    
                                    self?.outageState = .error(errorState: .other)
                                }
                            }
                        } else {
                            Log.warning("Maintenance mode active: Outage.")
                            
                            self?.outageState = .error(errorState: .maintenanceMode)
                        }
                        
                        
                        if !maintenanceMode.usage {
                            guard let premiseNumber = accountDetail.premiseNumber,
                                  accountDetail.isAMIAccount,
                                  !accountDetail.isFinaled else {
                                Log.error("Account invalid for usage data due to non existant premise number, non AMI, or finaled")
                                
                                self?.usageState = .unavailable(account: account)
                                return
                            }
                            
                            // MARK: Usage
                            UsageService.fetchBillForecast(accountNumber: accountDetail.accountNumber,
                                                           premiseNumber: premiseNumber) { [weak self] networkResult in
                                switch networkResult {
                                case .success(let billForecastResult):
                                    Log.info("Usage Data Fetched.")
                                    
                                    let usage = WatchUsage(accountDetails: accountDetail,
                                                           billForecastResult: billForecastResult)
                                    self?.usageState = .loaded(usage: usage,
                                                               account: account)
                                case .failure(let error):
                                    Log.error("Failed to retrieve usage data: \(error.localizedDescription)")
                                    
                                    self?.usageState = .error(errorState: .other)
                                }
                            }
                        } else {
                            Log.warning("Maintenance mode active: Usage.")
                            
                            self?.usageState = .error(errorState: .maintenanceMode)
                        }
                    case .failure(let error):
                        Log.error("Failed to Fetch Account Details. \(error.localizedDescription)")
                        
                        self?.outageState = .error(errorState: .other)
                        self?.usageState = .error(errorState: .other)
                        #warning("bill state goes here")
                    //                        self?.billState = .error(errorState: .other)
                    }
                }
                
            case .failure(let error):
                Log.error("Failed to retrieve maintenance mode: \(error.localizedDescription)")
                
                self?.outageState = .error(errorState: .other)
                self?.usageState = .error(errorState: .other)
                #warning("bill state goes here")
            //                        self?.usageState = .error(errorState: .other)
            }
        }
    }
}
