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
    
    var mockScheduledPayments: [PaymentItem?] = []
    
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
                                                                                              scheduledPayment: PaymentItem(amount: 82, date: tenDaysFromToday)))
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
                                              billingInfo: BillingInfo(netDueAmount: 0,
                                                                       lastPaymentAmount: 200,
                                                                       lastPaymentDate: now,
                                                                       dueByDate: now,
                                                                       billDate: yesterday))
            return .just(accountDetail)
            
        case "thankYouForPaymentOTP":
            RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = PaymentDetails(amount: 234,
                                                                                             date: Date().addingTimeInterval(-3600),
                                                                                             confirmationNumber: "123456")
            let accountDetail = AccountDetail(accountNumber: "1234")
            return .just(accountDetail)
            
        // Past Due
        case "finaled":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       pastDueAmount: 200),
                                              flagFinaled: true)
            return .just(accountDetail)
            
        case "pastDue":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       pastDueAmount: 140,
                                                                       dueByDate: tenDaysFromToday,
                                                                       currentDueAmount: 60))
            return .just(accountDetail)
            
        case "pastDueEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       pastDueAmount: 200))
            return .just(accountDetail)
            
        // Resotre Service
        case "restoreService":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       restorationAmount: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       currentDueAmount: 150),
                                              isCutOutNonPay: true)
            return .just(accountDetail)
            
        case "restoreServiceEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       restorationAmount: 350,
                                                                       dueByDate: tenDaysFromToday),
                                              isCutOutNonPay: true)
            return .just(accountDetail)
            
        // Avoid Shutoff
        case "eligibleForCutoff":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       pastDueAmount: 100,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 100,
                                                                       currentDueAmount: 100),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoff":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 100,
                                                                       currentDueAmount: 150),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffExtended":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 100,
                                                                       currentDueAmount: 150,
                                                                       turnOffNoticeExtendedDueDate: tenDaysFromToday),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffPastEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 200,
                                                                       currentDueAmount: 150),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffPastEqualExtended":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 200,
                                                                       currentDueAmount: 150,
                                                                       turnOffNoticeExtendedDueDate: tenDaysFromToday),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffPastNetEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 200),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffPastNetEqualExtended":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 200,
                                                                       turnOffNoticeExtendedDueDate: tenDaysFromToday),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffAllEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 350),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        case "avoidShutoffAllEqualExtended":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       dueByDate: tenDaysFromToday,
                                                                       disconnectNoticeArrears: 350,
                                                                       turnOffNoticeExtendedDueDate: tenDaysFromToday),
                                              isCutOutIssued: true)
            return .just(accountDetail)
            
        // Catch Up
        case "catchUp":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       amtDpaReinst: 100,
                                                                       dueByDate: tenDaysFromToday,
                                                                       atReinstateFee: 5,
                                                                       currentDueAmount: 150),
                                              isLowIncome: false)
            return .just(accountDetail)
            
        case "catchUpPastEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 200,
                                                                       amtDpaReinst: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       atReinstateFee: 5,
                                                                       currentDueAmount: 150),
                                              isLowIncome: false)
            return .just(accountDetail)
            
        case "catchUpPastNetEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       amtDpaReinst: 200,
                                                                       dueByDate: tenDaysFromToday,
                                                                       atReinstateFee: 5),
                                              isLowIncome: false)
            return .just(accountDetail)
            
        case "catchUpAllEqual":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 350,
                                                                       pastDueAmount: 350,
                                                                       amtDpaReinst: 350,
                                                                       dueByDate: tenDaysFromToday,
                                                                       atReinstateFee: 5),
                                              isLowIncome: false)
            return .just(accountDetail)
            
        case "paymentPending":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 200,
                                                                       remainingBalanceDue: 100,
                                                                       dueByDate: tenDaysFromToday,
                                                                       pendingPayments: [PaymentItem(amount: 100,
                                                                                                     status: .pending)]))
            return .just(accountDetail)
            
        case "paymentsPending":
            let accountDetail = AccountDetail(accountNumber: "1234",
                                              billingInfo: BillingInfo(netDueAmount: 300,
                                                                       dueByDate: tenDaysFromToday,
                                                                       pendingPayments: [PaymentItem(amount: 250,
                                                                                                     status: .pending),
                                                                                         PaymentItem(amount: 50,
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
    
    func fetchScheduledPayments(accountNumber: String) -> Observable<[PaymentItem]> {
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        switch loggedInUsername {
        case "scheduledPayment", "autoPayScheduled":
            let scheduledPayments = [PaymentItem(amount: 82)]
            return .just(scheduledPayments)
        default:
            guard let accountIndex = mockAccounts.firstIndex(where: { $0.accountNumber == accountNumber}) else {
                return .error(ServiceError(serviceMessage: "No account detail found for the provided account."))
            }
            
            guard mockScheduledPayments.count >= accountIndex + 1, mockScheduledPayments[accountIndex] != nil else {
                return .just([])
            }
            
            return .just([mockScheduledPayments[accountIndex]!])
        }
    }
    
    func fetchSERResults(accountNumber: String) -> Observable<[SERResult]> {
        return .just([])
    }
}
