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
    @Published var billingState: BillState = .loading
    
    init() {
        setLoginStatus()
        fetchData()
        
        WatchSessionController.shared.authTokenDidUpdate = { [weak self] () -> Void in
            self?.setLoginStatus()
            self?.fetchData()
        }
        
        WatchSessionController.shared.outageReportedFromPhone = { [weak self] () -> Void in
            let account = WatchAccount(account: AccountsStore.shared.currentAccount)
            self?.outageState = .loaded(outage: PreviewData.outageReported,
                                        account: account)
        }
    }
}

// MARK: Network Requests

extension NetworkController {
    private func fetchAccounts(completion: @escaping (Result<Void, Error>) -> Void) {
        accountListState = .loading
        
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
                if error == .invalidToken {
                    Log.error("Invalid oauth token, sign user out: \(error.localizedDescription)")
                    
                    self?.isLoggedIn = false
                    
                    self?.accountListState = .loading
                    self?.outageState = .loading
                    self?.usageState = .loading
                    self?.billingState = .loading
                } else if  error == .passwordProtected {
                    Log.error("Failed to retrieve account list.  Password Protected Account.")
                    
                    self?.outageState = .error(errorState: .passwordProtected)
                    self?.usageState = .error(errorState: .passwordProtected)
                    self?.billingState = .error(errorState: .passwordProtected)
                } else {
                    Log.error("Failed to retrieve account list: \(error.localizedDescription)")
                    
                    self?.accountListState = .error(errorState: .other)
                    self?.outageState = .error(errorState: .other)
                    self?.usageState = .error(errorState: .other)
                    self?.billingState = .error(errorState: .other)
                }
                
                completion(.failure(error))
            }
        }
    }
    
    private func setLoginStatus() {
        let authToken = KeychainController.default.string(forKey: .tokenKeychainKey)
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
        
        outageState = .loading
        usageState = .loading
        billingState = .loading
        
        Log.info("Fetching Maintenance Mode Status...")
        
        guard KeychainController.default.string(forKey: .tokenKeychainKey) != nil,
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
                    self?.billingState = .error(errorState: .maintenanceMode)
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
                            self?.billingState = .error(errorState: .passwordProtected)
                            return
                        }
                        
                        let account = WatchAccount(account: AccountsStore.shared.currentAccount)
                        
                        // MARK: Billing
                        let bill = WatchBill(accountDetails: accountDetail)
                        self?.billingState = .loaded(bill: bill, account: account)
                        
                        if !maintenanceMode.outage {
                            // MARK: Outage
                            Log.info("Fetching Outage...")
                            OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { [weak self] networkResult in
                                switch networkResult {
                                case .success(let outageStatus):
                                    Log.info("Outage Status Fetched.")
                                    
                                    let watchOutage = WatchOutage(outageStatus: outageStatus)
                                    if outageStatus.isGasOnly {
                                        self?.outageState = .gasOnly(account: account)
                                    } else if outageStatus.isFinaled || outageStatus.isNonService {
                                        self?.outageState = .unavailable(account: account)
                                    } else {
                                        self?.outageState = .loaded(outage: watchOutage,
                                                                    account: account)
                                    }
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
                            Log.info("Fetching Bill Forecast...")
                            UsageService.fetchBillForecast(accountNumber: accountDetail.accountNumber,
                                                           premiseNumber: premiseNumber) { [weak self] networkResult in
                                switch networkResult {
                                case .success(let billForecastResult):
                                    Log.info("Usage Data Loaded.")
                                    
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
                        self?.billingState = .error(errorState: .other)
                    }
                }
                
            case .failure(let error):
                Log.error("Failed to retrieve maintenance mode: \(error.localizedDescription)")
                
                self?.outageState = .error(errorState: .other)
                self?.usageState = .error(errorState: .other)
                self?.billingState = .error(errorState: .other)
            }
        }
    }
}
