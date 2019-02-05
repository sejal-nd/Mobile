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
    
    func fetchAccounts() -> Observable<[Account]> {
        do {
            let accounts: [Account] = try MockUser.current.accounts
                .map { try MockJSONManager.shared.mappableObject(fromFile: .accounts, key: $0.dataKey(forFile: .accounts)) }
            
            AccountsStore.shared.accounts = accounts
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
            let accounts: [Account] = try MockUser.current.accounts
                .map { try MockJSONManager.shared.mappableObject(fromFile: .accounts, key: $0.dataKey(forFile: .accounts)) }
            
            AccountsStore.shared.accounts = accounts
            AccountsStore.shared.currentIndex = 0
            AccountsStore.shared.customerIdentifier = "123"
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = nil
        } catch {
            return
        }
    }
    
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        let dataFile = MockJSONManager.File.accountDetails
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        
        if key == MockDataKey.thankYouForPaymentOTP {
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = PaymentDetails(amount: 234,
                                                                                             date: Date.now.addingTimeInterval(-3600),
                                                                                             confirmationNumber: "123456")
        }
        
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
    
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int) -> Observable<Void> {
        return .just(())
    }
    
    func setDefaultAccount(account: Account) -> Observable<Void> {
        return .just(())
    }
    
    func fetchSSOData(accountNumber: String, premiseNumber: String) -> Observable<SSOData> {
        let ssoData = SSOData.from(["utilityCustomerId": "1234", "ssoPostURL": "https://google.com", "relayState": "https://google.com", "samlResponse": "test"])!
        return .just(ssoData)
    }
    
    func fetchScheduledPayments(accountNumber: String) -> Observable<[PaymentItem]> {
        let dataFile = MockJSONManager.File.payments
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableArray(fromFile: dataFile, key: key)
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        return .just([])
    }
}
