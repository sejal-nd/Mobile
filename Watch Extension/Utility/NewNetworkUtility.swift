//
//  NewNetworkUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/16/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

enum NetworkError: Error {
    case missingToken
    case maintenanceMode
    case passwordProtected
    case invalidAccount
    case fetchError
}

final class NetworkUtilityNew {
    
    private let disposeBag = DisposeBag()
    
    private var pollingTimer: Timer!
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(currentAccountDidUpdate(_:)), name: Notification.Name.currentAccountUpdated, object: nil)
        
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        pollingTimer.invalidate()
    }
    
    private func fetchAccountList(result: @escaping (Result<[Account], NetworkError>) -> ()) {
        dLog("Fetching Accounts...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil else {
            dLog("No Auth Token: Account list fetch termimated.")
            result(.failure(.missingToken))
            return
        }
        
        let accountService = MCSAccountService()
        accountService.fetchAccounts().subscribe(onNext: { accounts in
            // handle success
            guard let firstAccount = AccountsStore.shared.accounts.first else {
                dLog("No first account in account list: Terminated.")
                result(.failure(.invalidAccount))
                return
            }
            
            if AccountsStore.shared.currentIndex == nil {
                AccountsStore.shared.currentIndex = 0
            }
            
            NotificationCenter.default.post(name: Notification.Name.defaultAccountSet, object: firstAccount)
            
            dLog("Accounts Fetched.")
            
            result(.success(accounts))
        }, onError: { error in
            dLog("Failed to retrieve account list: \(error.localizedDescription)")
            result(.failure(.fetchError))
        }).disposed(by: disposeBag)
    }
    
    
    // do not reload account list with polling timer
    // do not show loading with polling
    
    //todo all notifications will trigger here
    public func fetchData(shouldLoadAccountList: Bool) {
        let dispatchQueue = DispatchQueue.global(qos: .background)
        let semaphore = DispatchSemaphore(value: 1)
        
        dispatchQueue.async { [weak self] in
            if shouldLoadAccountList {
                self?.fetchAccountList { result in
                    switch result {
                    case.success(let accounts):
                        break
                    case .failure(let error):
                        break
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                
                self?.fetchFeatureData { result in
                    switch result {
                    case .success(let temp):
                        break
                    case .failure(let error):
                        break
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                
            } else {
                self?.fetchFeatureData { result in
                    switch result {
                    case .success(let accounts):
                        break
                    case .failure(let error):
                        break
                    }
                }
            }
            
            
        }
    }
    
}
 

// MARK: - Feature Fetches

extension NetworkUtilityNew {
    // this is where the magic happens
    private func fetchFeatureData(completion: @escaping (Result<[Account], NetworkError>) -> ()) {
        // Fetch Account Details + Maintenance Mode
        fetchAccountDetailsWithData { [weak self] accountDetailResult in
            switch accountDetailResult {
            case .success(let accountDetails):
                
                // Fetch Outage Status
                self?.fetchOutageStatus { outageResult in
                    switch outageResult {
                    case .success(let outageStatus):
                        break
                    case .failure(let error):
                        break
                    }
                }

                // Fetch Usage Data
                self?.fetchUsageData(accountDetail: accountDetails, result: { useageResult in
                    switch useageResult {
                    case .success(let billForecast):
                        break
                    case .failure(let error):
                        break
                    }
                })
            case .failure(let error):
                break
            }
        }
    }
    
    
    // todo we need to rename this
    
    /// Fetches the account details for the current user triggering various networkUtilityDelegate methods along the way.
    ///
    /// - Note: AccountDetails contains Billing data `accountDetails.billingInfo` and isPasswordProtectedStatus.
    ///
    /// - Parameter maintenanceModeStatus: status of maintenance mode, used to determine if bill is in maintenance mode or not.
    ///
    /// - Requires: That the JWT token has been saved into the local keychain.
    ///
    /// - Important:
    ///     - success: Triggers delegate method to IC informing it that the account details did update.
    ///                Also triggers the `fetchData()` call for outage, usage, and bill.  This can return that the account
    ///                is password protected.
    ///     - noAuthToken: Triggers delegate method for an error due to no jwt token presen: Service Error Code: 981156.
    ///     - error: Triggers delegate method for a general error occured attempting to fetch account details.
    private func fetchAccountDetailsWithData(completion: @escaping (Result<AccountDetail, NetworkError>) -> ()) {
        guard KeychainUtility.shared[keychainKeys.authToken] != nil,
            let _ = AccountsStore.shared.currentIndex else {
                dLog("Could not find auth token in Accounts Manager Fetch Account Details.")
                completion(.failure(.missingToken))
                return
        }
        
        let dispatchQueue = DispatchQueue.global(qos: .background)
        let semaphore = DispatchSemaphore(value: 1)
        
        dispatchQueue.async { [weak self] in
            // Maintenance Mode
            self?.fetchMaintenanceModeStatus { result in
                switch result {
                case .success(let maintenance):
                    if maintenance.billStatus {
                        completion(.failure(.maintenanceMode))
                        return
                    } else {
                        break
                    }
                case .failure(_):
                    completion(.failure(.fetchError))
                }
                semaphore.signal()
            }
            semaphore.wait()
            // Account Details
            self?.fetchAccountDetails { result in
                switch result {
                case .success(let accountDetails):
                    if accountDetails.isPasswordProtected {
                        completion(.failure(.passwordProtected))
                    } else {
                        completion(.success(accountDetails))
                    }
                case .failure(_):
                    completion(.failure(.fetchError))
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    // Fetch Account Details: We need this to determine if the current account is password protected.
    public func fetchAccountDetails(result: @escaping (Result<AccountDetail, NetworkError>) -> ()) {
        dLog("Fetching Account Details...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil,
            let _ = AccountsStore.shared.currentIndex else {
            dLog("Could not find auth token in Accounts Manager Fetch Account Details.")
            result(.failure(.missingToken))
            return
        }
        
        let accountService = MCSAccountService()
        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
            .subscribe(onNext: { accountDetail in
                // handle success
                dLog("Account Details Fetched.")
                
                result(.success(accountDetail))
            }, onError: { error in
                // handle error
                dLog("Failed to Fetch Account Details. \(error.localizedDescription)")
                result(.failure(.fetchError))
            })
            .disposed(by: disposeBag)
    }
    
    /// Fetches if maintenance mode is active for any/all services.
    ///
    /// - Note: success here does not mean maintenance mode is active, rather it means maintenanceMode data was returned.
    ///
    /// - Important:
    ///     - success: completion handler for `fetchData()` call resulting in maintenance mode data.
    ///     - error: completion handler for `fetchData()` call resulting in an error state.
    private func fetchMaintenanceModeStatus(result: @escaping (Result<Maintenance, NetworkError>) -> ()) {
        dLog("Fetching Maintenance Mode Status...")

        let authService = MCSAuthenticationService()

        authService.getMaintenanceMode()
            .subscribe(onNext: { maintenance in
                dLog("Maintenance Mode Fetched.")

                result(.success(maintenance))
            }, onError: { error in
                dLog("Failed to retrieve maintenance mode: \(error.localizedDescription)")
                result(.failure(.fetchError))
            })
            .disposed(by: disposeBag)
    }
    
    /// Fetches outage data fort he current account triggering various networkUtilityDelegate methods along the way.
    ///
    /// - Requires: That the JWT token has been saved into the local keychain.
    ///
    /// - Important:
    ///     - success: completion handler for `fetchData()` call resulting in outage data.
    ///     - error: completion handler for `fetchData()` call resulting in an error state.
    private func fetchOutageStatus(result: @escaping (Result<OutageStatus, NetworkError>) -> ()) {
        dLog("Fetching Outage Status...")

        guard let _ = AccountsStore.shared.currentIndex else {
            dLog("Failed to retreive current account while fetching outage status.")
            result(.failure(.missingToken))
            return
        }

        let outageService = MCSOutageService()

        outageService.fetchOutageStatus(account: AccountsStore.shared.currentAccount).subscribe(onNext: { outageStatus in
            dLog("Outage Status Fetched.")
            result(.success(outageStatus))
            }, onError: { error in
                // handle error
                dLog("Failed to retrieve outage status: \(error.localizedDescription)")
                result(.failure(.fetchError))
        })
        .disposed(by: disposeBag)
    }
    
    /// Fetches usage data fort he current account triggering various networkUtilityDelegate methods along the way.
    ///
    /// - Parameter accountDetail: details of current account needed for account number & accunt premise number.
    ///
    /// - Requires: That the JWT token has been saved into the local keychain.
    ///
    /// - Important:
    ///     - success: completion handler for `fetchData()` call resulting in usage data.
    ///     - error: completion handler for `fetchData()` call resulting in an error state.
    private func fetchUsageData(accountDetail: AccountDetail, result: @escaping (Result<BillForecastResult, NetworkError>) -> ()) {
        dLog("Fetching Usage Data...")

        guard accountDetail.isAMIAccount, let premiseNumber = accountDetail.premiseNumber else {
            result(.failure(.invalidAccount))
            return
        }
        let accountNumber = accountDetail.accountNumber

        MCSUsageService(useCache: false).fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber).subscribe(onNext: { billForecastResult in
            result(.success(billForecastResult))
            }, onError: { usageError in
                dLog("Failed to retrieve usage data: \(usageError.localizedDescription)")
                result(.failure(.fetchError))
        })
            .disposed(by: disposeBag)
    }
    
}
    
    
    
    // MARK: - Timer
    
    extension NetworkUtilityNew {
    
    /// Reload Data every 15 minutes without the loading indicator if the app is reachable
    @objc private func reloadPollingData() {
        dLog("Polling new data...")
        guard WatchSessionManager.shared.isReachable() else { return }
        
        fetchData(shouldLoadAccountList: false)
    }
        
    }
    
    
    
    
    // MARK: - Current Account Did Update
    
    extension NetworkUtilityNew {
    
    // User selected account did update
    @objc func currentAccountDidUpdate(_ notification: NSNotification) {
        dLog("Current Account Did Update")
        
        // Reset timer
        pollingTimer.invalidate()
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
        
        fetchData(shouldLoadAccountList: true)
    }
}

// fetch account lists


// we can simplify this code by using semaphores, then we do not need to nest calls

// 1.  Fetch maintenance mode

// 2. fetch account details

// 3. fetch usage data

// 4.  fetch outage


// Notes:

// toggle for showing or not showing loading indicator

// All Screens must get the updates on completion: Notification center?

// polling reload every 15 mins

// pass from app delegate as opposed to singleton

// two public methods: Load Data & loadAccountList

// Unsure where in the app we will load data as this does not return a callback, rather it triggers notification center items


// public API: fetchData and outageStatus

// note: internal polling needs to fetch data with and without re fetching the account list.
