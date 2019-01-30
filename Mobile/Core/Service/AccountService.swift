//
//  AccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

/// The AccountService protocol defines the interface necessary
/// to deal with fetching and updating accoutns associated with
/// the currently logged in customer.
protocol AccountService {

    
    /// Fetch a page of accounts for the current customer.
    func fetchAccounts() -> Observable<[Account]>
    
    
    /// Fetch an accounts detailed information.
    ///
    /// - Parameters:
    ///   - account: the account to fetch
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail>
    
    #if os(iOS)
    /// Updates the Release of Information in preferences for the specified account (PECO ONLY)
    ///
    /// - Parameters:
    ///   - account: the account to update
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int) -> Observable<Void>
    
    
    /// Sets the user's default account to the specified account
    ///
    /// - Parameters:
    ///   - account: the account to set as default
    func setDefaultAccount(account: Account) -> Observable<Void>
    #endif
    
    /// Gets single sign-on info so that we can display the logged-in user's usage web view
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch SSOData for
    ///   - premiseNumber: the premiseNumber to fetch SSOData for
    func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData>
    
    /// Gets recent scheduled, processing, and pending payments
    func fetchScheduledPayments(accountNumber: String) -> Observable<[PaymentItem]>
    
    /// Gets SER event results
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]>
}
