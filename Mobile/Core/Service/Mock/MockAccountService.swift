//
//  MockAccountService.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockAccountService: AccountService {
    
    var mockAccounts: [Account] = [
        Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!,
        Account.from(["accountNumber": "9836621902", "address": "E. Fort Ave, Ste. 200"])!,
    ]
    var mockAccountDetails: [AccountDetail] = [
        AccountDetail.from(["accountNumber": "1234567890", "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])!,
        AccountDetail.from(["accountNumber": "9836621902", "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])!,
    ]
    
    func fetchAccounts(completion: @escaping (ServiceResult<[Account]>) -> Void) {
        var accounts = mockAccounts
    
//        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername)
//        if loggedInUsername == "billCardNoDefaultPayment" {
//            accounts = [Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!]
//        }
        
        AccountsStore.shared.accounts = accounts
        AccountsStore.shared.currentAccount = accounts[0]
        AccountsStore.shared.customerIdentifier = "123"
        completion(ServiceResult.success(accounts as [Account]))
    }
    
    func fetchAccountDetail(account: Account, completion: @escaping (ServiceResult<AccountDetail>) -> Void) {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        if loggedInUsername == "billCardNoDefaultPayment" || loggedInUsername == "billCardWithDefaultPayment" {
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 200))
            completion(ServiceResult.success(accountDetail))
            return
        }
        if loggedInUsername == "billCardWithDefaultCcPayment" || loggedInUsername == "billCardWithExpiredDefaultPayment"{
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 200), isResidential: true)
            completion(ServiceResult.success(accountDetail))
            return
        }
        if loggedInUsername == "billCardWithDefaultCcPayment" || loggedInUsername == "billCardWithExpiredDefaultPayment"{
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 200), isResidential: true)
            completion(ServiceResult.Success(accountDetail))
            return
        }
        if loggedInUsername == "scheduledPayment" {
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(scheduledPayment: PaymentItem(amount: 200)))
            completion(ServiceResult.success(accountDetail)) // fix for sprint 4 merge...
            return
        }
        if loggedInUsername == "thankYouForPayment" {
            let now = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(lastPaymentAmount: 200, lastPaymentDate: now, billDate: yesterday))
            completion(ServiceResult.success(accountDetail))
            return
        }
        if loggedInUsername == "pastDue" {
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 200, pastDueAmount: 200))
            completion(ServiceResult.success(accountDetail))
            return
        }
        if loggedInUsername == "avoidShutoff" {
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(disconnectNoticeArrears: 200, isDisconnectNotice: true))
            completion(ServiceResult.success(accountDetail))
            return
        }
        if loggedInUsername == "paymentPending" {
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(pendingPayments: [PaymentItem(amount: 200, status: .pending)]))
            completion(ServiceResult.success(accountDetail))
            return
        }
        
        guard let accountIndex = mockAccounts.index(of: account) else {
            completion(.failure(ServiceError(serviceMessage: "No account detail found for the provided account.")))
            return
        }
        let accountDetail = mockAccountDetails[accountIndex]
        
        guard accountDetail.accountNumber != "failure" else {
            completion(.failure(ServiceError(serviceMessage: "Account detail fetch failed.")))
            return
        }
        
        completion(ServiceResult.success(accountDetail))
    }
    
    func updatePECOReleaseOfInfoPreference(account: Account, selectedIndex: Int, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(ServiceResult.success(()))
    }
    
    func setDefaultAccount(account: Account, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(ServiceResult.success(()))
    }
    
    func fetchSSOData(accountNumber: String, premiseNumber: String, completion: @escaping (ServiceResult<SSOData>) -> Void) {
        let ssoData = SSOData.from(["utilityCustomerId": "1234", "ssoPostURL": "https://google.com", "relayState": "https://google.com", "samlResponse": "test"])!
        completion(ServiceResult.success(ssoData))
    }
}
