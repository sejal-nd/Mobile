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
        let key = MockUser.current.currentAccount.dataKey(forFile: .accountDetails)
        
        if key == MockDataKey.thankYouForPaymentOTP {
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = PaymentDetails(amount: 234,
                                                                                             date: Date.now.addingTimeInterval(-3600),
                                                                                             confirmationNumber: "123456")
        }
        
        do {
            let accountDetail: AccountDetail = try MockJSONManager.shared.mappableObject(fromFile: .accountDetails, key: key)
            return .just(accountDetail)
        } catch {
            return .error(error)
        }
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
        let key = MockUser.current.currentAccount.dataKey(forFile: .payments)
        
        do {
            let payments: [PaymentItem] = try MockJSONManager.shared.mappableArray(fromFile: .payments, key: key)
            return .just(payments)
        } catch {
            return .error(error)
        }
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        return .just([])
    }
}
