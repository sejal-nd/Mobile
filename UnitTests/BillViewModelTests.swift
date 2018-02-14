//
//  BillViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class BillViewModelTests: XCTestCase {
    
    var viewModel: BillViewModel!
    var accountService: MockAccountService!
    let disposeBag = DisposeBag()
    var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        
        let mockAccounts = [
            Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!,
            Account.from(["accountNumber": "9836621902", "address": "E. Fort Ave, Ste. 200"])!,
            Account.from(["accountNumber": "7003238921", "address": "E. Andre Street"])!,
            Account.from(["accountNumber": "5591032201", "address": "7700 Presidents Street"])!,
            Account.from(["accountNumber": "5591032202", "address": "7701 Presidents Street"])!,
        ]
        
        AccountsStore.sharedInstance.currentAccount = mockAccounts[0]
        accountService = MockAccountService()
        accountService.mockAccounts = mockAccounts
        viewModel = BillViewModel(accountService: accountService)
        scheduler = TestScheduler(initialClock: 0)
    }
    
    func simulateRefreshPulls(at times: [Int]) {
        let events: [Recorded<Event<FetchingAccountState>>] = times.map { next($0, .refresh) }
        let refreshPulls = scheduler.createHotObservable(events)
        refreshPulls.bind(to: viewModel.fetchAccountDetail).disposed(by: disposeBag)
    }
    
    func simulateAccountSwitches(at times: [Int]) {
        let events: [Recorded<Event<Account>>] = zip(times, accountService.mockAccounts).map(next)
        let accountSwitches = scheduler.createHotObservable(events)
        accountSwitches
            .do(onNext: {
                AccountsStore.sharedInstance.currentAccount = $0
            })
            .map { _ in FetchingAccountState.switchAccount }
            .bind(to: viewModel.fetchAccountDetail)
            .disposed(by: disposeBag)
    }
    
    // Tests changes in the `totalAmountText` value after switching
    // through 5 different accounts, then refreshing 2 times.
    func testTotalAmountText() {
        let totalAmounts: [Double?] = [4, 5000, nil, -68.04, 435.323]
        let expectedValues: [String] = [
            "$4.00",
            "$5,000.00",
            "--",
            Environment.sharedInstance.opco == .bge ? "-$68.04" : "$0.00",
            "$435.32",
            "$435.32",
            "$435.32"
        ]
        
        let switchAccountEventTimes = Array(0..<totalAmounts.count)
        let refreshEventTimes = Array(totalAmounts.count..<expectedValues.count)
        
        accountService.mockAccountDetails = totalAmounts.map {
            AccountDetail(billingInfo: BillingInfo(netDueAmount: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        simulateRefreshPulls(at: refreshEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.totalAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes + refreshEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `totalAmountDescriptionText` value after switching
    // through different accounts.
    func testTotalAmountDescriptionText() {
        let totalAmounts: [Double?] = [4, -5000, 435.323, 68.04, nil]
        let pastDueAmounts: [Double?] = [4, 26.32, nil, 0, nil]
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dueByDates: [Date?] = ["02/12/2018", "03/14/2018", "12/16/2018", nil, "06/12/2018"]
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        
        let expectedValues: [String] = [
            "Total Amount Due Immediately",
            Environment.sharedInstance.opco == .bge ? "No Amount Due - Credit Balance" : "Total Amount Due By 03/14/2018",
            "Total Amount Due By 12/16/2018",
            "Total Amount Due By --",
            "Total Amount Due By 06/12/2018"
        ]
        
        let switchAccountEventTimes = Array(0..<totalAmounts.count)
        
        accountService.mockAccountDetails = zip(totalAmounts, zip(pastDueAmounts, dueByDates)).map {
            AccountDetail(billingInfo: BillingInfo(netDueAmount: $0.0, pastDueAmount: $0.1.0, dueByDate: $0.1.1))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.totalAmountDescriptionText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `restoreServiceAmountText` value after switching
    // through different accounts.
    func testRestoreServiceAmountText() {
        let restorationAmounts: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedValues: [String] = ["$4.00", "$5,000.00", "$435.32", "-$68.04", "--"]
        
        let switchAccountEventTimes = Array(0..<restorationAmounts.count)
        
        accountService.mockAccountDetails = restorationAmounts.map {
            AccountDetail(billingInfo: BillingInfo(restorationAmount: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.restoreServiceAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `catchUpAmountText` value after switching
    // through different accounts.
    func testCatchUpAmountText() {
        let amtDpaReinsts: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedValues: [String] = ["$4.00", "$5,000.00", "$435.32", "-$68.04", "--"]
        
        let switchAccountEventTimes = Array(0..<amtDpaReinsts.count)
        
        accountService.mockAccountDetails = amtDpaReinsts.map {
            AccountDetail(billingInfo: BillingInfo(amtDpaReinst: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.catchUpAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `catchUpDateText` value after switching
    // through different accounts.
    func testCatchUpDateText() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dateStrings: [String?] = ["02/12/2018", "03/14/2018", "12/16/2018", nil, "06/12/2018"]
        let dueByDates: [Date?] = dateStrings
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        
        let expectedValues: [String] = ["Due by 02/12/2018",
                                        "Due by 03/14/2018",
                                        "Due by 12/16/2018",
                                        "Due by ",
                                        "Due by 06/12/2018"]
        
        let switchAccountEventTimes = Array(0..<dueByDates.count)
        
        accountService.mockAccountDetails = dueByDates.map {
            AccountDetail(billingInfo: BillingInfo(dueByDate: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.catchUpDateText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `catchUpDisclaimerText` value after switching
    // through different accounts.
    func testCatchUpDisclaimerText() {
        let amtDpaReinsts: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedCurrencyValues: [String] = ["$4.00", "$5,000.00", "$435.32", "-$68.04", "--"]
        let text = "You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill."
        let expectedValues = expectedCurrencyValues.map {
            String(format: text, $0)
        }
        
        let switchAccountEventTimes = Array(0..<amtDpaReinsts.count)
        
        accountService.mockAccountDetails = amtDpaReinsts.map {
            AccountDetail(billingInfo: BillingInfo(atReinstateFee: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.catchUpDisclaimerText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests the `avoidShutoffText` value, which is only dependent on OpCo.
    func testAvoidShutoffText() {
        let expectedText: String
        switch Environment.sharedInstance.opco {
        case .bge:
            expectedText = NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
        case .comEd, .peco:
            expectedText = NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")
        }
        
        XCTAssertEqual(expectedText, viewModel.avoidShutoffText)
    }
    
    // Tests the `avoidShutoffA11yText` value, which is only dependent on OpCo.
    func testAvoidShutoffA11yText() {
        let expectedText: String
        switch Environment.sharedInstance.opco {
        case .bge:
            expectedText = NSLocalizedString("Amount Due to Avoid Service Interruption", comment: "")
        case .comEd, .peco:
            expectedText = NSLocalizedString("Amount Due to Avoid shut-off", comment: "")
        }
        
        XCTAssertEqual(expectedText, viewModel.avoidShutoffA11yText)
    }
    
    // Tests changes in the `avoidShutoffAmountText` value after switching
    // through different accounts.
    func testAvoidShutoffAmountText() {
        let disconnectNoticeArrears: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedValues: [String] = ["$4.00", "$5,000.00", "$435.32", "-$68.04", "--"]
        
        let switchAccountEventTimes = Array(0..<disconnectNoticeArrears.count)
        
        accountService.mockAccountDetails = disconnectNoticeArrears.map {
            AccountDetail(billingInfo: BillingInfo(disconnectNoticeArrears: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.avoidShutoffAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `avoidShutoffDueDateText` value after switching
    // through different accounts.
    func testAvoidShutoffDueDateText() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dateStrings: [String?] = ["02/12/2018", "03/14/2018", "12/16/2018", nil, "06/12/2018"]
        let dueByDates: [Date?] = dateStrings
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        
        let expectedValues: [String]
        switch Environment.sharedInstance.opco {
        case .bge:
            expectedValues = ["Due by 02/12/2018",
                              "Due by 03/14/2018",
                              "Due by 12/16/2018",
                              "Due by --",
                              "Due by 06/12/2018"]
        case .comEd, .peco:
            expectedValues = ["Due Immediately",
                              "Due Immediately",
                              "Due Immediately",
                              "Due Immediately",
                              "Due Immediately"]
        }
        
        let switchAccountEventTimes = Array(0..<dueByDates.count)
        
        accountService.mockAccountDetails = dueByDates.map {
            AccountDetail(billingInfo: BillingInfo(dueByDate: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.avoidShutoffDueDateText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }

    // Tests changes in the `pastDueAmountText` value after switching
    // through different accounts.
    func testPastDueAmountText() {
        let pastDueAmount: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedValues: [String] = ["$4.00", "$5,000.00", "$435.32", "-$68.04", "--"]
        
        let switchAccountEventTimes = Array(0..<pastDueAmount.count)
        
        accountService.mockAccountDetails = pastDueAmount.map {
            AccountDetail(billingInfo: BillingInfo(pastDueAmount: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.pastDueAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests the `pendingPaymentAmounts` value.
    func testPendingPaymentAmounts() {
        let paymentItems = [PaymentItem(amount: 4, status: .scheduled),
                            PaymentItem(amount: 5000, status: .pending),
                            PaymentItem(amount: 435.323, status: .scheduled),
                            PaymentItem(amount: -68.04, status: .pending)]
        let expectedValues = [[5000.0]]
        
        let switchAccountEventTimes = [0]
        
        accountService.mockAccountDetails = [AccountDetail(billingInfo: BillingInfo(pendingPayments: paymentItems))]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver([Double].self)
        viewModel.pendingPaymentAmounts.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        for (index, expectedEvent) in expectedEvents.enumerated() {
            guard let expectedElement = expectedEvent.value.element,
                let observedElement = observer.events[index].value.element else {
                    XCTFail("No valid element at the given index")
                    break
            }
            XCTAssertTrue(expectedElement.elementsEqual(observedElement))
        }
        
        // May be able to replace the above loop with this line when Swift 4.1 is released
        // (conditional protocol conformance, equatable arrays)
//        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests the `remainingBalanceDueText` value, which is only dependent on OpCo.
    func testRemainingBalanceDueText() {
        let expectedText: String?
        switch Environment.sharedInstance.opco {
        case .bge:
            expectedText = nil
        case .comEd, .peco:
            expectedText = NSLocalizedString("Remaining Balance Due", comment: "")
        }
        
        XCTAssertEqual(expectedText, viewModel.remainingBalanceDueText)
    }
    
    // Tests changes in the `remainingBalanceDueAmountText` value after switching
    // through different accounts.
    func testRemainingBalanceDueAmountText() {
        let netDueAmounts: [Double?] = [nil, 5000, 0, nil]
        let pendingPayments: [Double?] = [nil, 5000, 1, -68.04]
        let remainingBalanceDues: [Double?] = [4, 5000, 435.323, nil]
        let expectedValues: [String] = ["$0.00", "$0.00", "$435.32", "--"]
        
        let switchAccountEventTimes = Array(0..<netDueAmounts.count)
        
        accountService.mockAccountDetails = zip(netDueAmounts, zip(remainingBalanceDues, pendingPayments)).map {
            let paymentItems: [PaymentItem]
            if let paymentAmount = $0.1.1 {
                paymentItems = [PaymentItem(amount: paymentAmount, status: .pending)]
            } else {
                paymentItems = []
            }
            return AccountDetail(billingInfo: BillingInfo(netDueAmount: $0.0,
                                                          remainingBalanceDue: $0.1.0,
                                                          pendingPayments: paymentItems))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.remainingBalanceDueAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `remainingBalanceDueDateText` value after switching
    // through different accounts.
    func testRemainingBalanceDueDateText() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dateStrings: [String?] = ["02/12/2018", "03/14/2018", "12/16/2018", nil, "06/12/2018"]
        let dueByDates: [Date?] = dateStrings
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        
        let expectedValues = ["Due by 02/12/2018",
                              "Due by 03/14/2018",
                              "Due by 12/16/2018",
                              "--",
                              "Due by 06/12/2018"]

        let switchAccountEventTimes = Array(0..<dueByDates.count)
        
        accountService.mockAccountDetails = dueByDates.map {
            AccountDetail(billingInfo: BillingInfo(dueByDate: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.remainingBalanceDueDateText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests the `remainingBalancePastDueText` value, which is only dependent on OpCo.
    func testRemainingBalancePastDueText() {
        let expectedText: String?
        switch Environment.sharedInstance.opco {
        case .bge:
            expectedText = nil
        case .comEd, .peco:
            expectedText = NSLocalizedString("Remaining Past Balance Due ", comment: "")
        }
        
        XCTAssertEqual(expectedText, viewModel.remainingBalancePastDueText)
    }
    
    // Tests changes in the `billIssuedAmountText` value after switching
    // through different accounts.
    func testBillIssuedAmountText() {
        let switchAccountEventTimes = [0]
        
        accountService.mockAccountDetails = [AccountDetail()]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.billIssuedAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(!observer.events.map { $0.value.element! == nil }.contains(false))
    }
    
    // Tests changes in the `billIssuedDateText` value after switching
    // through different accounts.
    func testBillIssuedDateText() {
        let switchAccountEventTimes = [0]
        
        accountService.mockAccountDetails = [AccountDetail()]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.billIssuedDateText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(!observer.events.map { $0.value.element! == nil }.contains(false))
    }
    
    // Tests changes in the `paymentReceivedAmountText` value after switching
    // through different accounts.
    func testPaymentReceivedAmountText() {
        let lastPaymentAmounts: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedValues: [String] = ["$4.00", "$5,000.00", "$435.32", "-$68.04", "--"]
        
        let switchAccountEventTimes = Array(0..<lastPaymentAmounts.count)
        
        accountService.mockAccountDetails = lastPaymentAmounts.map {
            AccountDetail(billingInfo: BillingInfo(lastPaymentAmount: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.paymentReceivedAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `paymentReceivedDateText` value after switching
    // through different accounts.
    func testPaymentReceivedDateText() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dateStrings: [String?] = ["02/12/2018", "03/14/2018", "12/16/2018", nil, "06/12/2018"]
        let lastPaymentDates: [Date?] = dateStrings
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        
        let expectedValues = ["Payment Date 02/12/2018",
                              "Payment Date 03/14/2018",
                              "Payment Date 12/16/2018",
                              nil,
                              "Payment Date 06/12/2018"]
        
        let switchAccountEventTimes = Array(0..<lastPaymentDates.count)
        
        accountService.mockAccountDetails = lastPaymentDates.map {
            AccountDetail(billingInfo: BillingInfo(lastPaymentDate: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.paymentReceivedDateText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        let observedEqualsExpected = !zip(observer.events, expectedEvents)
            .map { $0.0.value.element! == $0.1.value.element! }
            .contains(false)
        
        XCTAssert(observedEqualsExpected)
    }
    
    // Tests changes in the `creditAmountText` value after switching
    // through different accounts.
    func testCreditAmountText() {
        let netDueAmounts: [Double?] = [4, 5000, 435.323, -68.04, nil]
        let expectedValues: [String] = ["$4.00", "$5,000.00", "$435.32", "$68.04", "--"]
        
        let switchAccountEventTimes = Array(0..<netDueAmounts.count)
        
        accountService.mockAccountDetails = netDueAmounts.map {
            AccountDetail(billingInfo: BillingInfo(netDueAmount: $0))
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.creditAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
}

