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
    
    var mockAccounts: [Account] = [
        Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!,
        Account.from(["accountNumber": "9836621902", "address": "E. Fort Ave, Ste. 200"])!,
        Account(accountNumber: "4234332133",
                address: "E. Fort Ave, Ste. 201",
                premises: ["1", "2", "3"].map { Premise(premiseNumber: $0, addressLine: [$0]) },
                currentPremise: Premise(premiseNumber: "1"))
    ]
    var mockAccountDetails: [AccountDetail] = [
        AccountDetail.from(["accountNumber": "1234567890", "premiseNumber": "4783934345", "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])!,
        AccountDetail.from(["accountNumber": "9836621902", "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])!,
    ]
    
    var mockRecentPayments: [RecentPayments] = []
    
    func fetchAccounts() -> Observable<[Account]> {
        var accounts = mockAccounts
    
//        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.LoggedInUsername)
//        if loggedInUsername == "billCardNoDefaultPayment" {
//            accounts = [Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!]
//        }
        
        AccountsStore.shared.accounts = accounts
        AccountsStore.shared.currentAccount = accounts[0]
        AccountsStore.shared.customerIdentifier = "123"
        RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = nil
        return .just(accounts)
    }
    
    func fetchAccountDetail(account: Account) -> Observable<AccountDetail> {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        let tenDaysFromToday = Calendar.opCo.startOfDay(for: Date()).addingTimeInterval(864_000)
        switch loggedInUsername {
        case "billCardNoDefaultPayment", "billCardWithDefaultPayment":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday))
            return .just(accountDetail)
            
        case "billCardWithDefaultCcPayment", "billCardWithExpiredDefaultPayment":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday),
                                              isResidential: false)
            return .just(accountDetail)
            
        case "minPaymentAmount":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 0.001,
                                                                       dueByDate: tenDaysFromToday))
            return .just(accountDetail)
            
        case "maxPaymentAmount":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 100_000_000,
                                                                       dueByDate: tenDaysFromToday))
            return .just(accountDetail)
            
        case "cashOnly":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday),
                                              isCashOnly: true)
            return .just(accountDetail)
            
        case "scheduledPayment":
            let accountDetail = AccountDetail(accountNumber: "1234", billingInfo: BillingInfo(netDueAmount: 82,
                                                                                              dueByDate: tenDaysFromToday,
                                                                                              scheduledPayment: PaymentItem(amount: 82)))
            return .just(accountDetail)
            
        case "autoPay":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 82,
                                                                       dueByDate: tenDaysFromToday),
                                              isAutoPay: true)
            return .just(accountDetail)
            
        case "autoPayScheduled":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 82,
                                                                       dueByDate: tenDaysFromToday,
                                                                       scheduledPayment: PaymentItem(amount: 82)),
                                              isAutoPay: true)
            return .just(accountDetail)
            
        case "thankYouForPayment":
            let now = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(lastPaymentAmount: 200,
                                                                       lastPaymentDate: now,
                                                                       billDate: yesterday))
            return .just(accountDetail)
            
        case "thankYouForPaymentOTP":
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = PaymentDetails(amount: 234,
                                                                                             date: Date().addingTimeInterval(-3600),
                                                                                             confirmationNumber: "123456")
            let accountDetail = AccountDetail(accountNumber: "1234")
            return .just(accountDetail)
            
        case "pastDue":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       pastDueAmount: 200))
            return .just(accountDetail)
            
        case "restoreService":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       restorationAmount: 200,
                                                                       dueByDate: tenDaysFromToday),
                                              isCutOutNonPay: true)
            return .just(accountDetail)
            
        case "avoidShutoff":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 200,
                                                                       isDisconnectNotice: true))
            return .just(accountDetail)
            
        case "catchUp":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       amtDpaReinst: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       atReinstateFee: 5),
                                              isLowIncome: false)
            return .just(accountDetail)
            
        case "paymentPending":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       pendingPayments: [PaymentItem(amount: 200,
                                                                                                     status: .pending)]))
            return .just(accountDetail)
            
        case "credit":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: -350.34))
            return .just(accountDetail)
            
        case "billNotReady":
            let accountDetail = AccountDetail(accountNumber: "1234")
            return .just(accountDetail)
            
        default:
            guard let accountIndex = mockAccounts.index(of: account) else {
                return .error(ServiceError(serviceMessage: "No account detail found for the provided account."))
            }
            let accountDetail = mockAccountDetails[accountIndex]
            
            guard accountDetail.accountNumber != "failure" else {
                return .error(ServiceError(serviceMessage: "Account detail fetch failed."))
            }
            
            return .just(accountDetail)
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
    
    func fetchRecentPayments(accountNumber: String) -> Observable<RecentPayments> {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        switch loggedInUsername {
        case "scheduledPayment", "autoPayScheduled":
            let recentPayments = RecentPayments(scheduledPayment: PaymentItem(amount: 82))
            return .just(recentPayments)
        case "paymentPending":
            let recentPayments = RecentPayments(pendingPayments: [PaymentItem(amount: 200,
                                                                              status: .pending)])
            return .just(recentPayments)
        default:
            guard let accountIndex = mockAccounts.firstIndex(where: { $0.accountNumber == accountNumber}) else {
                return .error(ServiceError(serviceMessage: "No account detail found for the provided account."))
            }
            
            guard mockRecentPayments.count >= accountIndex + 1 else {
                return .just(RecentPayments())
            }
            
            return .just(mockRecentPayments[accountIndex])
        }
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        return .just([])
    }
}
