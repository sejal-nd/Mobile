//
//  MockUser.swift
//  Mobile
//
//  Created by Samuel Francis on 1/28/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

fileprivate let keyDefault = "default"
fileprivate let keyError = "error"

struct MockUser {
    static var current = MockUser.default
    static let `default` = MockUser()
    
    let accounts: [MockAccount]
    
    /// Initializes a mock user with a list of accounts
    init(accounts: [MockAccount]) {
        self.accounts = accounts
    }
    
    /// Initializes a mock user with a single account according to the provided keys
    init(accountsKey: MockDataKey = .default,
         accountDetailsKey: MockDataKey = .default,
         paymentsKey: MockDataKey = .default,
         outageStatusKey: MockDataKey = .default,
         billComparisonKey: MockDataKey = .default,
         billForecastKey: MockDataKey = .default,
         maintenanceKey: MockDataKey = .default) {
        let account = MockAccount(accountsKey: accountsKey,
                                  accountDetailsKey: accountDetailsKey,
                                  paymentsKey: accountDetailsKey,
                                  outageStatusKey: outageStatusKey,
                                  billComparisonKey: billComparisonKey,
                                  billForecastKey: billForecastKey,
                                  maintenanceKey: maintenanceKey)
        accounts = [account]
    }
    
    /// Initializes a mock user with a single account, applying the global key to every service
    init(globalKey key: MockDataKey = .default) {
        let account = MockAccount(globalKey: key)
        accounts = [account]
    }
    
    /// Initializes a mock user with a list of accounts, applying the global keys to every service per account
    init(globalKeys keys: MockDataKey...) {
        accounts = keys.map(MockAccount.init)
    }
    
    /// Initializes a mock user with an acccount according to the supplied string.
    /// If the string has no corresponding mock account key, the default key is used.
    /// Used for UI tests where only a username string is entered via the sign in workflow.
    init(username: String) {
        let key = MockDataKey(rawValue: username) ?? .default
        let account = MockAccount(globalKey: key)
        accounts = [account]
    }
    
}

struct MockAccount {
    let accountsKey: String
    let accountDetailsKey: String
    let paymentsKey: String
    let outageStatusKey: String
    let billComparisonKey: String
    let billForecastKey: String
    let maintenanceKey: String
    
    init(accountsKey: MockDataKey = .default,
         accountDetailsKey: MockDataKey = .default,
         paymentsKey: MockDataKey = .default,
         outageStatusKey: MockDataKey = .default,
         billComparisonKey: MockDataKey = .default,
         billForecastKey: MockDataKey = .default,
         maintenanceKey: MockDataKey = .default) {
        self.accountsKey = accountsKey.rawValue
        self.accountDetailsKey = accountDetailsKey.rawValue
        self.paymentsKey = paymentsKey.rawValue
        self.outageStatusKey = outageStatusKey.rawValue
        self.billComparisonKey = billComparisonKey.rawValue
        self.billForecastKey = billForecastKey.rawValue
        self.maintenanceKey = maintenanceKey.rawValue
    }
    
    init(globalKey key: MockDataKey = .default) {
        self.init(accountsKey: key,
                  accountDetailsKey: key,
                  paymentsKey: key,
                  outageStatusKey: key,
                  billComparisonKey: key,
                  billForecastKey: key,
                  maintenanceKey: key)
    }
    
    /// Used for UI tests where only a username String is provided
    init(username: String) {
        let key = MockDataKey(rawValue: username) ?? .default
        self.init(globalKey: key)
    }
    
}

enum MockDataKey: String {
    // Billing
    case billCardNoDefaultPayment
    case billCardWithDefaultPayment
    case billCardWithDefaultCcPayment
    case billCardWithExpiredDefaultPayment
    case billNoDueDate
    case minPaymentAmount
    case maxPaymentAmount
    case cashOnly
    case scheduledPayment
    case autoPay
    case autoPayEligible
    case bgEasy
    case budgetBill
    case budgetBillEligible
    case eBill
    case eBillEligible
    case finaledStatus
    case thankYouForPayment
    case thankYouForPaymentOTP
    case paymentPending
    case paymentsPending
    case credit
    case billNotReady
    case bgeControlGroup
    case finaledResidential
    case invalidServiceType
    case electricOnly
    case gasAndElectric
    case billBreakdown
    
    // Precarious
    case finaled
    case pastDue
    case pastDueEqual
    case restoreService
    case restoreServiceEqual
    case eligibleForCutoff
    case avoidShutoff
    case avoidShutoffExtended
    case avoidShutoffPastEqual
    case avoidShutoffPastEqualExtended
    case avoidShutoffPastNetEqual
    case avoidShutoffPastNetEqualExtended
    case avoidShutoffAllEqual
    case avoidShutoffAllEqualExtended
    case catchUp
    case catchUpPastEqual
    case catchUpPastNetEqual
    case catchUpAllEqual
    
    // Outage
    //case powerOn
    //case powerOut
    case gasOnly
    case noPay
    //case reportOutage
    case outageNonServiceAgreement
    
    // Usage
    case referenceEndDate
    case comparedEndDate
    case referenceMinHeight
    case comparedMinHeight
    case projectedCost
    case projectedUsage
    case projectedCostAndUsage
    case projectedCostAndUsageOpower
    case projectedDate
    case projectionLessThan7
    case projectionMoreThan7
    case projectionSixDaysOut
    case projectionThreeDaysOut
    case hasForecastReferenceHighest
    case hasForecastComparedHighest
    case hasForecastForecastHighest
    case noForecastReferenceHighest
    case noForecastComparedHighest
    case forecastStartEndDate
    case comparedReferenceStartEndDate
    case avgTemp
    case zeroCostDifference
    case positiveCostDifference
    case negativeCostDifference
    case likelyReasonsNoData
    case likelyReasonsAboutSame
    case likelyReasonsGreater
    case likelyReasonsLess
    
    // Maintenance
    case maintAll
    case maintAllTabs
    case maintNotHome
    
    // General
    case error
    case `default`
}
