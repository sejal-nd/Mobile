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
        RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = nil
        completion(ServiceResult.success(accounts as [Account]))
    }
    
    func fetchAccountDetail(account: Account, completion: @escaping (ServiceResult<AccountDetail>) -> Void) {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        switch loggedInUsername {
        case "billCardNoDefaultPayment", "billCardWithDefaultPayment":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       dueByDate: Date().addingTimeInterval(864_000)))
            return completion(ServiceResult.success(accountDetail))
            
        case "billCardWithDefaultCcPayment", "billCardWithExpiredDefaultPayment":
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 200), isResidential: false)
            return completion(ServiceResult.success(accountDetail))
            
        case "minPaymentAmount":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 0.001,
                                                                       dueByDate: Date().addingTimeInterval(864_000)))
            return completion(ServiceResult.success(accountDetail))
            
        case "maxPaymentAmount":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 100_000_000,
                                                                       dueByDate: Date().addingTimeInterval(864_000)))
            return completion(ServiceResult.success(accountDetail))
            
        case "cashOnly":
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 200, dueByDate: Date().addingTimeInterval(864_000)), isCashOnly: true)
            return completion(ServiceResult.success(accountDetail))
            
        case "scheduledPayment":
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 82,
                                                                                              dueByDate: Date().addingTimeInterval(864_000),
                                                                                              scheduledPayment: PaymentItem(amount: 82)))
            return completion(ServiceResult.success(accountDetail))
            
        case "autoPay":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 82,
                                                                       dueByDate: Date().addingTimeInterval(864_000)),
                                              isAutoPay: true)
            return completion(ServiceResult.success(accountDetail))
            
        case "autoPayScheduled":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 82,
                                                                       dueByDate: Date().addingTimeInterval(864_000),
                                                                       scheduledPayment: PaymentItem(amount: 82)),
                                              isAutoPay: true)
            return completion(ServiceResult.success(accountDetail))
            
        case "thankYouForPayment":
            let now = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(lastPaymentAmount: 200,
                                                                       lastPaymentDate: now,
                                                                       billDate: yesterday))
            return completion(ServiceResult.success(accountDetail))
            
        case "thankYouForPaymentOTP":
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = PaymentDetails(amount: 234,
                                                                                             date: Date().addingTimeInterval(-3600))
            let accountDetail = AccountDetail(accountNumber: "1234")
            return completion(ServiceResult.success(accountDetail))
            
        case "pastDue":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       pastDueAmount: 200))
            return completion(ServiceResult.success(accountDetail))
            
        case "restoreService":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       restorationAmount: 200,
                                                                       dueByDate: Date().addingTimeInterval(864_000)),
                                              isCutOutNonPay: true)
            return completion(ServiceResult.success(accountDetail))
            
        case "avoidShutoff":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       dueByDate: Date().addingTimeInterval(864_000),
                                                                       disconnectNoticeArrears: 200,
                                                                       isDisconnectNotice: true))
            return completion(ServiceResult.success(accountDetail))
            
        case "catchUp":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       amtDpaReinst: 200,
                                                                       dueByDate: Date().addingTimeInterval(864_000),
                                                                       atReinstateFee: 5),
                                              isLowIncome: false)
            return completion(ServiceResult.success(accountDetail))
            
        case "paymentPending":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       dueByDate: Date().addingTimeInterval(864_000),
                                                                       pendingPayments: [PaymentItem(amount: 200,
                                                                                                     status: .pending)]))
            return completion(ServiceResult.success(accountDetail))
            
        case "credit":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: -350.34))
            return completion(ServiceResult.success(accountDetail))
            
        case "billNotReady":
            let accountDetail = AccountDetail(accountNumber: "1234")
            return completion(ServiceResult.success(accountDetail))
            
        default:
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
