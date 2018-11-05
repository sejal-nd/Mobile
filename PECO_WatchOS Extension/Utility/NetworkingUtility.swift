//
//  NetworkingController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/4/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

enum MainFeature {
    case outage
    case bill
    case usage
    case all
}

protocol NetworkingDelegate {
    /// Informs IC that outage status did update
    func outageStatusDidUpdate(_ outageStatus: OutageStatus)
    
    /// Informs IC that usage status did update
    func usageStatusDidUpdate(_ billForecast: BillForecastResult)
    
    /// Informs IC that account list did update
    func accountListDidUpdate(_ accounts: [Account])
    
    /// Informs IC that current account did update
    func currentAccountDidUpdate(_ account: Account)
    
    func accountDetailDidUpdate(_ accountDetail: AccountDetail)
    
    /// Informs IC that an error occured somewhere along the process.
    func error(_ serviceError: ServiceError, feature: MainFeature)
    
    /// Informs IC that the network requests are still loading.
    func loading(feature: MainFeature)
    
    /// Informs IC that maintenance mode is on for a specific data type.
    func maintenanceMode(feature: MainFeature)
}

class NetworkingUtility {
    
    static let shared = NetworkingUtility()
    
    public var networkUtilityDelegates = [NetworkingDelegate]()
    
    public var outageStatus: OutageStatus?
    
    private let accountManager = AccountsManager()
    
    private var pollingTimer: Timer!
    
    private init() {
        aLog("init network manager.")
        
        // Set Delegate
        AccountsStore.shared.accountStoreChangedDelegate = self
        
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
    }
    
    deinit {
        pollingTimer.invalidate()
    }
    
    
    // MARK: - Timer
    
    /// Reload Data every 15 minutes without the loading indicator if the app is reachable
    @objc private func reloadPollingData() {
        aLog("Polling new data...")
        guard WatchSessionManager.shared.isReachable() else { return }
        
        fetchData(shouldShowLoading: false, shouldLoadAccountList: false)
    }
    
    
    // MARK: - Public
    
    /// Fetches account list simultaneuly with the following: maintenance mode, account detail, outage, usage, and bill data triggering various networkUtilityDelegate methods along the way.
    ///
    /// - Parameter shouldFetchAccountList: Whether account list has been fetched, account list fetching is only required for the first call in the app.
    ///
    /// - Requires: That the JWT token has been saved into the local keychain.
    ///
    /// - Important:
    ///     - success: Triggers delegate method to IC informing it that outage, usage, and bill have updated.
    ///     - maintenanceMode: Triggers delegate method for maintenance mode.
    ///     - error: Triggers delegate method for a general error occured attempting to fetch data.
    public func fetchData(shouldShowLoading: Bool = true, shouldLoadAccountList: Bool = true) {
        
        if shouldShowLoading {
            // Trigger Loading in IC's
            networkUtilityDelegates.forEach { $0.loading(feature: .all) }
        }
        
        // Fetch Account List
        if shouldLoadAccountList {
            fetchAccountsWithData()
        }
        
        // Maintenance Mode Fetch
        fetchMaintenanceModeStatus { [weak self] (status, serviceError) in
            if let status = status {
                // if mm all status, make no network calls and present maintenance mode for everything.
                guard !status.allStatus else {
                    self?.networkUtilityDelegates.forEach { $0.maintenanceMode(feature: .all) }
                    return
                }
                
                self?.fetchAccountDetailsWithData(maintenanceModeStatus: status, completion: { [weak self] accountDetails in
                    guard let accountDetails = accountDetails else {
                        aLog("ERROR: Account Details is nil.")
                        self?.networkUtilityDelegates.forEach { $0.error(Errors.invalidInformation, feature: .all) }
                        return
                    }
                    
                    guard !accountDetails.isPasswordProtected else {
                        self?.networkUtilityDelegates.forEach { $0.error(Errors.passwordProtected, feature: .all) }
                        return
                    }
                    
                    // fetch usage
                    self?.fetchUsageData(accountDetail: accountDetails, success: { billForecast in
                        self?.networkUtilityDelegates.forEach { $0.usageStatusDidUpdate(billForecast) }
                    }, error: { serviceError in
                        self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .usage) }
                    })
                    
                    if status.outageStatus {
                        // Maint - Outage
                        self?.networkUtilityDelegates.forEach { $0.maintenanceMode(feature: .outage) }
                    } else {
                        // No Maint - Outage
                        self?.fetchOutageStatus(success: { [weak self] outageStatus in
                            self?.networkUtilityDelegates.forEach { $0.outageStatusDidUpdate(outageStatus) }
                            }, error: { serviceError in
                                self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .outage) }
                        })
                    }
                })
            } else {
                // Error status is nil
                aLog("ERROR: Maintenance Mode Status is nil.")
                
                self?.networkUtilityDelegates.forEach { $0.error(Errors.invalidInformation, feature: .all) }
            }
        }
    }
    
    
    // MARK: - Helper
    
    /// Fetches the account list for a specific unique user triggering various networkUtilityDelegate methods along the way.
    ///
    /// - Requires: That the JWT token has been saved into the local keychain.
    ///
    /// - Important:
    ///     - success: Triggers delegate method to IC informing it that the accountList did update.
    ///                Also triggers the fetch account details call to occur.
    ///     - noAuthToken: Triggers delegate method for an error due to no jwt token presen: Service Error Code: 981156.
    ///     - error: Triggers delegate method for a general error occured attempting to fetch the account list.
    private func fetchAccountsWithData() {
        accountManager.fetchAccounts(success: { [weak self] accounts in
            self?.networkUtilityDelegates.forEach { $0.accountListDidUpdate(accounts) }
        })
    }
    
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
    private func fetchAccountDetailsWithData(maintenanceModeStatus: Maintenance, completion: @escaping (AccountDetail?) -> Void) {
        accountManager.fetchAccountDetails(success: { [weak self] accountDetail in
            if accountDetail.isPasswordProtected {
                self?.networkUtilityDelegates.forEach { $0.error(Errors.passwordProtected, feature: .all) }
                completion(nil)
            } else {
                if maintenanceModeStatus.billStatus {
                    self?.networkUtilityDelegates.forEach { $0.maintenanceMode(feature: .bill) }
                } else {
                    self?.networkUtilityDelegates.forEach { $0.accountDetailDidUpdate(accountDetail) }
                }
                completion(accountDetail)
            }
            }, noAuthToken: { [weak self] serviceError in
                self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .all) }
                completion(nil)
            }, error: { [weak self] serviceError in
                self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .all) }
                completion(nil)
        })
    }
    
    /// Fetches if maintenance mode is active for any/all services.
    ///
    /// - Note: success here does not mean maintenance mode is active, rather it means maintenanceMode data was returned.
    ///
    /// - Important:
    ///     - success: completion handler for `fetchData()` call resulting in maintenance mode data.
    ///     - error: completion handler for `fetchData()` call resulting in an error state.
    private func fetchMaintenanceModeStatus(completion: @escaping (Maintenance?, ServiceError?) -> Void) {
        aLog("Fetching Maintenance Mode Status...")
        
        let authService = OMCAuthenticationService()
        
        authService.getMaintenanceMode { serviceResult in
            switch serviceResult {
            case .success(let status):
                aLog("Maintenance Mode Fetched.")
                completion(status, nil)
            case .failure(let error):
                aLog("Failed to retrieve maintenance mode: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    /// Fetches outage data fort he current account triggering various networkUtilityDelegate methods along the way.
    ///
    /// - Requires: That the JWT token has been saved into the local keychain.
    ///
    /// - Important:
    ///     - success: completion handler for `fetchData()` call resulting in outage data.
    ///     - error: completion handler for `fetchData()` call resulting in an error state.
    private func fetchOutageStatus(success: @escaping (OutageStatus) -> Void, error: @escaping (ServiceError) -> Void) {
        aLog("Fetching Outage Status...")
        
        guard let currentAccount = AccountsStore.shared.getSelectedAccount() else {
            aLog("Failed to retreive current account while fetching outage status.")
            error(Errors.noAccountsFound)
            return
        }
        
        let outageService = OMCOutageService()
        
        outageService.fetchOutageStatus(account: currentAccount) { [weak self] serviceResult in
            switch serviceResult {
            case .success(let outageStatus):
                aLog("Outage Status Fetched.")
                success(outageStatus)
                self?.outageStatus = outageStatus
            case .failure(let serviceError):
                aLog("Failed to retrieve outage status: \(serviceError.localizedDescription)")
                error(serviceError)
            }
        }
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
    private func fetchUsageData(accountDetail: AccountDetail, success: @escaping (BillForecastResult) -> Void, error: @escaping (ServiceError) -> Void) {
        aLog("Fetching Usage Data...")
        
        guard accountDetail.isAMIAccount, let premiseNumber = accountDetail.premiseNumber else {
            error(Errors.invalidInformation)
            return
        }
        let accountNumber = accountDetail.accountNumber
        
        OMCUsageService().fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber) { serviceResult in
            switch serviceResult {
            case .success(let billForcast):
                aLog("Usage Data Fetched.")
                success(billForcast)
            case .failure(let serviceError):
                aLog("Error Fetching Usage: \(serviceError.localizedDescription)...\(serviceError)")
                error(serviceError)
            }
        }
    }

}


// MARK: - Current Account Delegate Methods

extension NetworkingUtility: AccountStoreChangedDelegate {
    
    // User selected account did update
    func currentAccountDidUpdate(_ account: Account) {
        aLog("Current Account Did Update")
        
        // Reset timer
        pollingTimer.invalidate()
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
        
        networkUtilityDelegates.forEach { $0.currentAccountDidUpdate(account) }
        
        fetchData(shouldShowLoading: true, shouldLoadAccountList: false)
    }

}


// MARK: - Delegate Management

extension NetworkingUtility {
    
    /// Adds IC to networkUtilityDelegates.
    func addNetworkUtilityUpdateDelegate<T>(_ delegate: T) where T: NetworkingDelegate, T: Equatable {
        networkUtilityDelegates.append(delegate)
    }
    
    /// Removes IC from networkUtilityDelegates.
    func removeNetworkUtilityUpdateDelegate<T>(_ delegate: T) where T: NetworkingDelegate, T: Equatable {
        for (index, indexDelegate) in networkUtilityDelegates.enumerated() {
            if let indexDelegate = indexDelegate as? T, indexDelegate == delegate {
                networkUtilityDelegates.remove(at: index)
                break
            }
        }
    }

}
