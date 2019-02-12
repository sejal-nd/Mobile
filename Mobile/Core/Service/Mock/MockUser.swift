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
    static let `default` = MockUser(globalKeys: .default)
    
    let accounts: [MockAccount]
    
    var currentAccount: MockAccount {
        return accounts[AccountsStore.shared.currentIndex]
    }
    
    /// Initializes a mock user with a list of accounts
    init(accounts: [MockAccount]) {
        self.accounts = accounts
    }
    
    /// Initializes a mock user with a single account according to the provided keys
    init(dataKeys: [MockJSONManager.File: MockDataKey]) {
        let account = MockAccount(dataKeys: dataKeys)
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
        switch key {
        case .screenshots:
            accounts = [MockAccount](repeating: account, count: 3)
        default:
            accounts = [account]
        }
    }
    
}

struct MockAccount {
    static let `default` = MockAccount(globalKey: .default)
    
    private let dataKeys: [MockJSONManager.File: MockDataKey]
    
    func dataKey(forFile file: MockJSONManager.File) -> MockDataKey {
        return dataKeys[file] ?? .default
    }
    
    init(dataKeys: [MockJSONManager.File: MockDataKey]) {
        self.dataKeys = dataKeys
    }
    
    init(globalKey key: MockDataKey) {
        let pairs = MockJSONManager.File.allCases.map { ($0, key) }
        dataKeys = Dictionary(uniqueKeysWithValues: pairs)
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
    case gasOnly
    case noPay
    //case outagePowerOn
    case outagePowerOut
    case reportOutageError
    case outageNonServiceAgreement
    case outageSmartMeter
    
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
    
    // App State
    case maintAll
    case maintAllTabs
    case maintAllTabsIOS
    case maintNotHome
    case maintNotHomeIOS
    case stormMode
    case urgentBanner
    
    // General
    case screenshots
    case error
    case `default`
}