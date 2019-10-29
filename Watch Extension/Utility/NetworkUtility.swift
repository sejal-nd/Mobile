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
        NotificationCenter.default.addObserver(self, selector: #selector(currentAccountDidUpdate(_:)), name: Notification.Name.currentAccountUpdated, object: nil)
        
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
        
        // Reset Maintenance Mode
        maintenanceModeStatuses.removeAll()
        
        if shouldLoadAccountList {
            dispatchQueue.async { [unowned self] in
                
                print("BEGIN fetching account list")
                self.fetchAccountList(result: { (result) in
                    switch result {
                    case .success(let accounts):
                        print("COMPLETE fetching account list")
                        self.accounts = accounts
                        self.notificationCenter.post(name: .accountListDidUpdate, object: accounts)
                        self.semaphore.signal()
                    case .failure(let error):
                        print("ERROR fetching account list")
                        self.error = (error, Feature.all)
                        self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.all))
                        self.semaphore.signal()
                        return
                    }
                })
                self.semaphore.wait()
                print("sema 0: \(self.semaphore.debugDescription)")
                self.fetchFeatureData(semaphore: self.semaphore, dispatchQueue: self.dispatchQueue)
            }
        } else {
            print("no acc list fetch")
            print("sema 4: \(self.semaphore.debugDescription)")
            dispatchQueue.async { [unowned self] in
                self.fetchFeatureData(semaphore: self.semaphore, dispatchQueue: self.dispatchQueue)
            }
        }
    }
    
}


// MARK: - Network Helper

extension NetworkUtility {
    
    /// Fetches Maintenance mode, then account details.  Once both succeed usage and outage are fetched at the same time.  Notifications are sent to the respective interface controllers.
    /// - Parameter semaphore: Prevents the need to nest too many async requests.
    /// - Parameter dispatchQueue: Allows network requests to occur in the background.
    private func fetchFeatureData(semaphore: DispatchSemaphore, dispatchQueue: DispatchQueue) {
        var maintenanceStatuses = [MaintenanceModeStatus]()
        
        guard KeychainUtility.shared[keychainKeys.authToken] != nil,
            let _ = AccountsStore.shared.currentIndex else {
                dLog("Could not find auth token in Accounts Manager Fetch Account Details.")
                self.notificationCenter.post(name: .errorDidOccur, object: (NetworkError.missingToken, Feature.all))
                return
        }
        
        print("BEGIN fetching maintenance mode.")
        fetchMaintenanceModeStatus { [weak self] (result) in
            switch result {
            case .success(let maintenance):
                maintenanceStatuses = self?.processMaintenanceMode(maintenance) ?? []
                print("SUCCESS fetching maintenance mode.")
                semaphore.signal()
            case .failure(let error):
                print("ERROR Fetching Mantenance mode.")
                self?.error = (error, Feature.all)
                self?.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.all))
                semaphore.signal()
                return
            }
        }
        semaphore.wait()
        print("sema 1: \(semaphore.debugDescription)")
        if isMaintenanceModeOnForFeature(feature: .all, currentStatuses: maintenanceStatuses) {
            return
        }
        
        print("BEGIN fetching account details")
        fetchAccountDetails { [unowned self] (result) in
            switch result {
            case .success(let accountDetails):
                print("SUCCESS fetching account details.")
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
                print("ERROR Fetching account details.")
                self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.all))
                semaphore.signal()
                return
            }
        }
        semaphore.wait()
        print("sema 2: \(semaphore.debugDescription)")
        guard let accountDetails = self.accountDetails else { return }
        
        if !self.isMaintenanceModeOnForFeature(feature: .outage, currentStatuses: maintenanceStatuses) {
            print("BEGIN fetching outage.")
            self.fetchOutageStatus { (result) in
                switch result {
                case .success(let outageStatus):
                    print("SUCCESS fetching outage.")
                    self.outageStatus = outageStatus
                    self.notificationCenter.post(name: .outageStatusDidUpdate, object: outageStatus)
                case .failure(let error):
                    print("ERROR Fetching outage.")
                    self.error = (error, .outage)
                    self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.outage))
                }
            }
        }

        if !self.isMaintenanceModeOnForFeature(feature: .usage, currentStatuses: maintenanceStatuses) {
            print("BEGIN fetching usage.")
            self.fetchUsageData(accountDetail: accountDetails) { (result) in
                switch result {
                case .success(let billForecastResult):
                    print("SUCCESS fetching usage.")
                    self.billForecast = billForecastResult
                    self.notificationCenter.post(name: .billForecastDidUpdate, object: billForecastResult)
                case .failure(let error):
                    print("ERROR Fetching usage.")
                    self.error = (error, .usage)
                    self.notificationCenter.post(name: .errorDidOccur, object: (error, Feature.usage))
                }
            }
        }
    }

    /// Sends notification to IC, and returns a boolean signifying if any form of maintenance mode is turned on.
    /// - Parameter maintenance: object returned from serivces of type `Maintenance`.
    private func processMaintenanceMode(_ maintenance: Maintenance) -> [MaintenanceModeStatus] {
        if maintenance.allStatus {
            maintenanceModeStatuses.append(MaintenanceModeStatus(maintenance: maintenance, feature: .all))
            print("sig all")
        }
        
        if maintenance.outageStatus {
            maintenanceModeStatuses.append(MaintenanceModeStatus(maintenance: maintenance, feature: .outage))
            print("sig outage")
        }
        
        if maintenance.usageStatus {
            maintenanceModeStatuses.append(MaintenanceModeStatus(maintenance: maintenance, feature: .usage))
            print("sig usage")
        }
        
        return maintenanceModeStatuses
    }
    
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
        guard KeychainUtility.shared[keychainKeys.authToken] != nil else {
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
            
            //            DispatchQueue.main.async {
            self?.defaultAccount = firstAccount
            self?.notificationCenter.post(name: .defaultAccountDidUpdate, object: firstAccount)
            //            }
            
            dLog("Accounts Fetched.")
            
            result(.success(accounts))
            }, onError: { error in
                dLog("Failed to retrieve account list: \(error.localizedDescription)")
                result(.failure(.fetchError))
        }).disposed(by: disposeBag)
    }
    
    /// Fetches key info about an account, specifically if the account is password protected.  Also required for fetching usage data.
    /// - Parameter result: Either `AccountDetail` or `NetworkError`.
    private func fetchAccountDetails(result: @escaping (Result<AccountDetail, NetworkError>) -> ()) {
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

extension NetworkUtility {
    
    /// Reload Data every 15 minutes without the loading indicator if the app is reachable
    @objc private func reloadPollingData() {
        dLog("Polling new data...")
        guard WatchSessionManager.shared.isReachable() else { return }
        
        fetchData(shouldLoadAccountList: false)
    }
    
}


// MARK: - Current Account Did Update

extension NetworkUtility {
    
    /// User selected account did update
    @objc func currentAccountDidUpdate(_ notification: NSNotification) {
        dLog("Current Account Did Update")
        
        guard let account = notification.object as? Account else {
            error = (.invalidAccount, .all)
            notificationCenter.post(name: .errorDidOccur, object: (NetworkError.invalidAccount, Feature.all))
            return
        }
        
        // Reset timer
        pollingTimer.invalidate()
        // Set a 15 minute polling timer here.
        pollingTimer = Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(reloadPollingData), userInfo: nil, repeats: true)
        
        fetchData(shouldLoadAccountList: false)
        
        defaultAccount = account
        notificationCenter.post(name: .defaultAccountDidUpdate, object: account)
    }
}
