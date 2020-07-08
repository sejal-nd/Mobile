//
//  MockAccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MockAccountService: AccountService {
    
    func fetchAccounts() -> Observable<[OldAccount]> {
        do {
            let accounts: [OldAccount] = try MockUser.current.accounts
                .map { try MockJSONManager.shared.mappableObject(fromFile: .accounts, key: $0.dataKey(forFile: .accounts)) }
            
//            AccountsStore.shared.accounts = accounts
            AccountsStore.shared.currentIndex = 0
            AccountsStore.shared.customerIdentifier = "123"
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = nil
            
            return .just(accounts)
        } catch {
            return .error(error)
        }
    }
    
    static func loadAccountsSync() {
        do {
            let accounts: [OldAccount] = try MockUser.current.accounts
                .map { try MockJSONManager.shared.mappableObject(fromFile: .accounts, key: $0.dataKey(forFile: .accounts)) }
            
//            AccountsStore.shared.accounts = accounts
            AccountsStore.shared.currentIndex = 0
            AccountsStore.shared.customerIdentifier = "123"
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = nil
        } catch {
            return
        }
    }
    
    func fetchAccountDetail(account: OldAccount) -> Observable<OldAccountDetail> {
        let dataFile = MockJSONManager.File.accountDetails
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        
        if key == .thankYouForPaymentOTP {
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] =
                PaymentDetails(amount: 234,
                               date: Date.now.addingTimeInterval(-3600),
                               confirmationNumber: "123456")
        }
        
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func fetchAccountDetail(account: OldAccount, alertPreferenceEligibilities: Bool) -> Observable<OldAccountDetail> {
        let dataFile = MockJSONManager.File.accountDetails
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        
        if key == .thankYouForPaymentOTP {
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] =
                PaymentDetails(amount: 234,
                               date: Date.now.addingTimeInterval(-3600),
                               confirmationNumber: "123456")
        }
        
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func updatePECOReleaseOfInfoPreference(account: OldAccount, selectedIndex: Int) -> Observable<Void> {
        return .just(())
    }
    
    func setDefaultAccount(account: OldAccount) -> Observable<Void> {
        return .just(())
    }
    
    func setAccountNickname(nickname: String, accountNumber: String) -> Observable<Void> {
        return .just(())
    }
    
    func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        let dataFile = MockJSONManager.File.ssoData
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func fetchFirstFuelSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        let dataFile = MockJSONManager.File.ssoData
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func fetchScheduledPayments(accountNumber: String) -> Observable<[PaymentItem]> {
        let dataFile = MockJSONManager.File.payments
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableArray(fromFile: dataFile, key: key)
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        let dataFile = MockJSONManager.File.serResults
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableArray(fromFile: dataFile, key: key)
    }
}
