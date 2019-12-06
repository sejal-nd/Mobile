//
//  NetworkTest.swift
//  Mobile
//
//  Created by Joseph Erlandson on 10/28/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift


// MARK: - Types

/// Possible errors or error states from network requests
enum NetworkError: Error {
    case missingToken
    case passwordProtected
    case invalidAccount
    case featureUnavailable
    case fetchError
}

/// Main page in the app.  Used for Error's and Maintenance Mode
enum Feature {
    case outage
    case bill
    case usage
    case all
}

struct MaintenanceModeStatus {
    var maintenance: Maintenance
    var feature: Feature
}


// MARK: - Network Utility

final class NetworkUtility {

    public static let shared = NetworkUtility()

    private let disposeBag = DisposeBag()
    private let notificationCenter = NotificationCenter.default
    private let dispatchQueue = DispatchQueue.global(qos: .background)
    private let semaphore = DispatchSemaphore(value: 0)
    private var pollingTimer: Timer!
    
    // In memory cache
    public var accounts = [Account]()
    public var defaultAccount: Account?
    public var outageStatus: OutageStatus?
    public var accountDetails: AccountDetail?
    public var billForecast: BillForecastResult?
    public var maintenanceModeStatuses = [MaintenanceModeStatus]()
    public var error: (NetworkError, Feature)?
    
    
    // MARK: - Life Cycle
    
    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(currentAccountDidUpdate(_:)),
                                               name: .currentAccountUpdated,
                                               object: nil)
        
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        pollingTimer.invalidate()
    }
    
    
    // MARK: - Public API
    
    /// Fetch all app data.  Due to all screens possibly loading at the same time we must fetch all data at once.
    /// - Parameter shouldLoadAccountList: true on fresh app launch, false if user selects a new account.
    public func fetchData(shouldLoadAccountList: Bool) {
        // Reset Maintenance Mode Statuses
        maintenanceModeStatuses.removeAll()
        
        var isPasswordProtected = false
        
        if shouldLoadAccountList {
            dispatchQueue.async { [unowned self] in
                self.fetchAccountList(result: { (result) in
                    switch result {
                    case .success(let accounts):
                        self.accounts = accounts
                        self.notificationCenter.post(name: .accountListDidUpdate, object: accounts)
                        self.semaphore.signal()
                    case .failure(let error):
                        if error == .passwordProtected {
                            self.error = (.passwordProtected, Feature.all)

                            self.notificationCenter.post(name: .errorDidOccur, object: (NetworkError.passwordProtected, Feature.all))
                            isPasswordProtected = true
                        } else {
                            self.error = (error, Feature.all)

                            self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.all))
                        }
                        
                        self.semaphore.signal()
                        return
                    }
                })
                self.semaphore.wait()
                
                guard !isPasswordProtected else { return }
                
                self.fetchFeatureData(semaphore: self.semaphore, dispatchQueue: self.dispatchQueue)
            }
        } else {
            dispatchQueue.async { [unowned self] in
                self.fetchFeatureData(semaphore: self.semaphore, dispatchQueue: self.dispatchQueue)
            }
        }
    }
    
    public func resetInMemoryCache() {
        accounts.removeAll()
        defaultAccount = nil
        outageStatus = nil
        accountDetails = nil
        billForecast = nil
        maintenanceModeStatuses.removeAll()
        error = nil
    }
    
}


// MARK: - Network Helper

extension NetworkUtility {
    
    /// Fetches Maintenance mode, then account details.  Once both succeed usage and outage are fetched at the same time.  Notifications are sent to the respective interface controllers.
    /// - Parameter semaphore: Prevents the need to nest too many async requests.
    /// - Parameter dispatchQueue: Allows network requests to occur in the background.
    private func fetchFeatureData(semaphore: DispatchSemaphore, dispatchQueue: DispatchQueue) {
        var maintenanceStatuses = [MaintenanceModeStatus]()
        
        guard KeychainManager.shared[keychainKeys.authToken] != nil,
            let _ = AccountsStore.shared.currentIndex else {
                dLog("Could not find auth token in Accounts Manager Fetch Account Details.")
                self.notificationCenter.post(name: .errorDidOccur, object: (NetworkError.missingToken, Feature.all))
                return
        }
        
        fetchMaintenanceModeStatus { [weak self] (result) in
            switch result {
            case .success(let maintenance):
                maintenanceStatuses = self?.processMaintenanceMode(maintenance) ?? []
                semaphore.signal()
            case .failure(let error):
                self?.error = (error, Feature.all)
                self?.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.all))
                semaphore.signal()
                return
            }
        }
        semaphore.wait()
        if isMaintenanceModeOnForFeature(feature: .all, currentStatuses: maintenanceStatuses) {
            return
        }
        
        fetchAccountDetails { [unowned self] (result) in
            switch result {
            case .success(let accountDetails):
                if accountDetails.isPasswordProtected {
                    self.notificationCenter.post(name: .errorDidOccur, object: (NetworkError.passwordProtected, Feature.all))
                    semaphore.signal()
                    return
                } else {
                    self.accountDetails = accountDetails
                    self.notificationCenter.post(name: .accountDetailsDidUpdate, object: accountDetails)
                }
                semaphore.signal()
            case .failure(let error):
                self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.all))
                semaphore.signal()
                return
            }
        }
        semaphore.wait()
        guard let accountDetails = self.accountDetails else { return }
        
        if !self.isMaintenanceModeOnForFeature(feature: .outage, currentStatuses: maintenanceStatuses) {
            self.fetchOutageStatus { (result) in
                switch result {
                case .success(let outageStatus):
                    self.outageStatus = outageStatus
                    self.notificationCenter.post(name: .outageStatusDidUpdate, object: outageStatus)
                case .failure(let error):
                    self.error = (error, .outage)
                    self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.outage))
                }
            }
        }

        if !self.isMaintenanceModeOnForFeature(feature: .usage, currentStatuses: maintenanceStatuses) {
            self.fetchUsageData(accountDetail: accountDetails) { (result) in
                switch result {
                case .success(let billForecastResult):
                    self.billForecast = billForecastResult
                    self.notificationCenter.post(name: .billForecastDidUpdate, object: billForecastResult)
                case .failure(let error):
                    self.error = (error, .usage)
                    self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.usage))
                }
            }
        }
    }

    /// Sends notification to IC, and returns a list containing the current maintenance mode status for each feature
    /// - Parameter maintenance: object returned from serivces of type `Maintenance`.
    private func processMaintenanceMode(_ maintenance: Maintenance) -> [MaintenanceModeStatus] {
        if maintenance.allStatus {
            maintenanceModeStatuses.append(MaintenanceModeStatus(maintenance: maintenance, feature: .all))
        }
        
        if maintenance.outageStatus {
            maintenanceModeStatuses.append(MaintenanceModeStatus(maintenance: maintenance, feature: .outage))
        }
        
        if maintenance.usageStatus {
            maintenanceModeStatuses.append(MaintenanceModeStatus(maintenance: maintenance, feature: .usage))
        }
        
        return maintenanceModeStatuses
    }
    
    /// Determines if a specific features maintenance mode is on given a list of current maintenance mode statuses.
    /// - Parameter feature: Feature that we want to check if maintenance mode is on for
    /// - Parameter currentStatuses: List of current maintenance mode statuses
    private func isMaintenanceModeOnForFeature(feature: Feature, currentStatuses: [MaintenanceModeStatus]) -> Bool {
        for status in currentStatuses {
            if feature == status.feature {
                self.notificationCenter.post(name: .maintenanceModeDidUpdate, object: status)
                return true
            }
        }
        return false
    }
    
}
 

// MARK: - Base Network Requests

extension NetworkUtility {
    
    /// Fetches the account list associated with a particular MyAccount.
    /// - Parameter result: Either an array of `Account` or a `NetworkError`.
    private func fetchAccountList(result: @escaping (Result<[Account], NetworkError>) -> ()) {
        guard KeychainManager.shared[keychainKeys.authToken] != nil else {
            dLog("No Auth Token: Account list fetch termimated.")
            result(.failure(.missingToken))
            return
        }
        
        let accountService = MCSAccountService()
        accountService.fetchAccounts().subscribe(onNext: { [weak self] accounts in
            // handle success
            guard let firstAccount = AccountsStore.shared.accounts.first else {
                dLog("No first account in account list: Terminated.")
                result(.failure(.invalidAccount))
                return
            }
            
            if AccountsStore.shared.currentIndex == nil {
                AccountsStore.shared.currentIndex = 0
            }
            
            self?.defaultAccount = firstAccount
            self?.notificationCenter.post(name: .defaultAccountDidUpdate, object: firstAccount)
            
            dLog("Accounts Fetched.")
            
            result(.success(accounts))
            }, onError: { error in
                if let serviceError = error as? ServiceError, serviceError.serviceCode == ServiceErrorCode.fnAccountProtected.rawValue {
                    dLog("Failed to retrieve account list.  Password Protected Account.")
                    result(.failure(.passwordProtected))
                } else {
                    dLog("Failed to retrieve account list: \(error.localizedDescription)")
                    result(.failure(.fetchError))
                }
        }).disposed(by: disposeBag)
    }
    
    /// Fetches key info about an account, specifically if the account is password protected.  Also required for fetching usage data.
    /// - Parameter result: Either `AccountDetail` or `NetworkError`.
    private func fetchAccountDetails(result: @escaping (Result<AccountDetail, NetworkError>) -> ()) {
        dLog("Fetching Account Details...")
        
        guard KeychainManager.shared[keychainKeys.authToken] != nil,
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
    
    /// Fetches maintenance mode status.
    ///
    /// - Note: Maintenance can be active for: all, outage, usage, or bill.  Success does not indicate whether maintenance mode is on, rather that data was successfully fetched.
    ///
    /// - Parameter result: Either `Maintenance` or `NetworkError`.
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
    
    /// Fetches outage data for the current account.
    /// - Parameter result: Either `OutageStatus` or `NetworkError`.
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

    /// Fetches projected usage data (striped bar graph on mobile app)
    /// - Parameter accountDetail: contains specific info about a users selected account.
    /// - Parameter result: Either `BillForecastResult` or `NetworkError`.
    private func fetchUsageData(accountDetail: AccountDetail, result: @escaping (Result<BillForecastResult, NetworkError>) -> ()) {
        dLog("Fetching Usage Data...")
        
        guard accountDetail.isAMIAccount else {
            dLog("Account invalid for usage data due to not being an AMI Account.")
            result(.failure(.featureUnavailable))
            return
        }
        
        guard let premiseNumber = accountDetail.premiseNumber else {
            dLog("Account invalid for usage data due to non existant premise number.")
            result(.failure(.invalidAccount))
            return
        }
        let accountNumber = accountDetail.accountNumber
        
        MCSUsageService(useCache: false).fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber).subscribe(onNext: { billForecastResult in
            dLog("Usage Data Fetched.")
            result(.success(billForecastResult))
        }, onError: { usageError in
            dLog("Failed to retrieve usage data: \(usageError.localizedDescription)")
            result(.failure(.fetchError))
        })
            .disposed(by: disposeBag)
    }
    
}


// MARK: - Timer

extension NetworkUtility {
    
    /// Reload Data every 15 minutes without the loading indicator if the app is reachable
    @objc private func reloadPollingData() {
        dLog("Polling new data...")
        guard WatchSessionManager.shared.validSession != nil else { return }
        
        fetchData(shouldLoadAccountList: false)
    }
    
}


// MARK: - Current Account Did Update

extension NetworkUtility {
    
    /// User selected account did update
    @objc func currentAccountDidUpdate(_ notification: NSNotification) {
        dLog("Current Account Did Update")
        
        guard let account = notification.object as? Account else {
            dLog("Failed to update current account, no account recieved in notification.")
            error = (.invalidAccount, .all)
            
            notificationCenter.post(name: .errorDidOccur, object: (NetworkError.invalidAccount, Feature.all))
            return
        }
        
        // Reset 15 min polling timer
        pollingTimer.invalidate()
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
        
        fetchData(shouldLoadAccountList: false)
        
        defaultAccount = account
        notificationCenter.post(name: .defaultAccountDidUpdate, object: account)
    }
}
