//
//  NetworkingController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 10/4/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

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
    func newAccountDidUpdate(_ account: Account)
    
    /// Informs IC that current account did update
    func currentAccountDidUpdate(_ account: Account)
    
    func accountDetailDidUpdate(_ accountDetail: AccountDetail)
    
    /// Informs IC that the account list and account details have both been updated (not neccisarrily successfully)
    func accountListAndAccountDetailsDidUpdate(accounts: [Account], accountDetail: AccountDetail?)
    
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
    
    // Outage Menu Population
    private let group = DispatchGroup()
    
    public var outageStatus: OutageStatus?
    
    private let accountManager = AccountsManager()
    
    private var pollingTimer: Timer!
    
    private var accounts = [Account]()
    private var accountDetails: AccountDetail?
    
    private let disposeBag = DisposeBag()

    private init() {
        dLog("init network manager.")
        
        // Observer Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(newAccountUpdate(_:)), name: Notification.Name.defaultAccountSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(currentAccountDidUpdate(_:)), name: Notification.Name.currentAccountUpdated, object: nil)
        
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        pollingTimer.invalidate()
    }
    

    // MARK: - Timer
    
    /// Reload Data every 15 minutes without the loading indicator if the app is reachable
    @objc private func reloadPollingData() {
        dLog("Polling new data...")
        guard WatchSessionManager.shared.isReachable() else { return }
        
        fetchData(shouldShowLoading: true, shouldLoadAccountList: false)
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
            fetchAccountsWithData { [weak self] success in
                guard success else { return }
                
                self?.fetchMainFeatureData()
            }
            return
        }
        
        fetchMainFeatureData()
    }
    
    /// Begins chain of MM -> Account details -> Outage + Usage
    /// We have in a separate function due to needing to nest it into fetch account list based on function boolean value
    private func fetchMainFeatureData() {
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
                        dLog("ERROR: Account Details is nil.")
                        
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
                        // No Maint - Fetch Outage
                        self?.fetchOutageStatus(success: { [weak self] outageStatus in
                            self?.networkUtilityDelegates.forEach { $0.outageStatusDidUpdate(outageStatus) }
                            }, error: { serviceError in
                                self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .outage) }
                        })
                    }
                    
                    // Account list and Account Detail calls have completed
                    self?.group.notify(queue: .main) { [weak self] in
                        guard let self = self else { return }
                        self.networkUtilityDelegates.forEach { $0.accountListAndAccountDetailsDidUpdate(accounts: self.accounts, accountDetail: self.accountDetails) }
                    }
                    
                })
            } else {
                // Error status is nil
                dLog("ERROR: Maintenance Mode Status is nil.")
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
    private func fetchAccountsWithData(completion: @escaping (Bool) -> Void) {
        group.enter()
        accountManager.fetchAccounts(success: { [weak self] accounts in
            self?.accounts = accounts
            self?.networkUtilityDelegates.forEach { $0.accountListDidUpdate(accounts) }
            self?.group.leave()
            completion(true)
        }) { [weak self] serviceError in
            self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .all) }
            self?.group.leave()
            completion(false)
        }
        
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
        group.enter()
        fetchAccountDetails(success: { [weak self] accountDetail in
            if accountDetail.isPasswordProtected {
                self?.networkUtilityDelegates.forEach { $0.error(Errors.passwordProtected, feature: .all) }
                completion(nil)
            } else {
                if maintenanceModeStatus.billStatus {
                    self?.networkUtilityDelegates.forEach { $0.maintenanceMode(feature: .bill) }
                } else {
                    self?.accountDetails = accountDetail
                    self?.networkUtilityDelegates.forEach { $0.accountDetailDidUpdate(accountDetail) }
                }
                completion(accountDetail)
            }
            self?.group.leave()
            }, noAuthToken: { [weak self] serviceError in
                self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .all) }
                self?.group.leave()
                completion(nil)
            }, error: { [weak self] serviceError in
                self?.networkUtilityDelegates.forEach { $0.error(serviceError, feature: .all) }
                self?.group.leave()
                completion(nil)
        })
    }
    
    // Fetch Account Details: We need this to determine if the current account is password protected.
    public func fetchAccountDetails(success: @escaping (AccountDetail) -> Void, noAuthToken: @escaping (ServiceError) -> Void, error: @escaping (ServiceError) -> Void) {
        dLog("Fetching Account Details...")
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil,
            let _ = AccountsStore.shared.currentIndex else {
            dLog("Could not find auth token in Accounts Manager Fetch Account Details.")
            noAuthToken(Errors.noAuthTokenFound)
            return
        }
        
        let accountService = MCSAccountService()
        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
            .subscribe(onNext: { accountDetail in
                // handle success
                dLog("Account Details Fetched.")
                
                success(accountDetail)
            }, onError: { accountDetailError in
                // handle error
                dLog("Failed to Fetch Account Details. \(accountDetailError.localizedDescription)")
                let serviceError = (accountDetailError as? ServiceError) ?? ServiceError(serviceCode: accountDetailError.localizedDescription, serviceMessage: nil, cause: nil)
                
                error(serviceError)
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
    private func fetchMaintenanceModeStatus(completion: @escaping (Maintenance?, ServiceError?) -> Void) {
        dLog("Fetching Maintenance Mode Status...")
        
        let authService = MCSAuthenticationService()

        authService.getMaintenanceMode()
            .subscribe(onNext: { maintenance in
                // handle success
                dLog("Maintenance Mode Fetched.")
                
                completion(maintenance, nil)
            }, onError: { error in
                // handle error
                dLog("Failed to retrieve maintenance mode: \(error.localizedDescription)")
                completion(nil, error as? ServiceError)
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
    private func fetchOutageStatus(success: @escaping (OutageStatus) -> Void, error: @escaping (ServiceError) -> Void) {
        dLog("Fetching Outage Status...")

        guard let _ = AccountsStore.shared.currentIndex else {
            dLog("Failed to retreive current account while fetching outage status.")
            error(Errors.noAccountsFound)
            return
        }
        
        let outageService = MCSOutageService()
        
        outageService.fetchOutageStatus(account: AccountsStore.shared.currentAccount).subscribe(onNext: { [weak self] outageStatus in
            // handle success
            dLog("Outage Status Fetched.")
            success(outageStatus)
            self?.outageStatus = outageStatus
            }, onError: { outageError in
                // handle error
                dLog("Failed to retrieve outage status: \(outageError.localizedDescription)")
                let serviceError = (outageError as? ServiceError) ?? ServiceError(serviceCode: outageError.localizedDescription, serviceMessage: nil, cause: nil)

                error(serviceError)
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
    private func fetchUsageData(accountDetail: AccountDetail, success: @escaping (BillForecastResult) -> Void, error: @escaping (ServiceError) -> Void) {
        dLog("Fetching Usage Data...")
        
        guard accountDetail.isAMIAccount, let premiseNumber = accountDetail.premiseNumber else {
            error(Errors.invalidInformation)
            return
        }
        let accountNumber = accountDetail.accountNumber
        
        MCSUsageService(useCache: false).fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber).subscribe(onNext: { billForecastResult in
            // handle success
            dLog("Usage Data Fetched.")
            success(billForecastResult)
            }, onError: { usageError in
                // handle error
                dLog("Failed to retrieve usage data: \(usageError.localizedDescription)")
                let serviceError = (usageError as? ServiceError) ?? ServiceError(serviceCode: usageError.localizedDescription, serviceMessage: nil, cause: nil)
                
                error(serviceError)
        })
            .disposed(by: disposeBag)
    }

}


// MARK: - Current Account Delegate Methods

extension NetworkingUtility {
    
    @objc func newAccountUpdate(_ notification: NSNotification) {

        guard let account = notification.object as? Account else { return }
        
        dLog("Initial Account Did Update")
        
        networkUtilityDelegates.forEach { $0.newAccountDidUpdate(account) }
    }
    
    // User selected account did update
    @objc func currentAccountDidUpdate(_ notification: NSNotification) {

        guard let account = notification.object as? Account else { return }
        
        dLog("Current Account Did Update")
        
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
