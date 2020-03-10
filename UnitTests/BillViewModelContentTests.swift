//
//  BillViewModelContentTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class BillViewModelContentTests: BillViewModelTests {
    
    // Tests changes in the `accountDetailError` value after switching
    // through different accounts.
    func testAccountDetailError() {
        MockUser.current = MockUser(globalKeys: .default, .error, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(ServiceError?.self)
        
        viewModel.accountDetailError.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.map { ($0.value.element!)!.serviceMessage! }, ["Account detail fetch failed."])
    }
    
    func testMaintenanceMode() {
        MockAppState.current = MockAppState(maintenanceKey: .maintAll)
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Event<(AccountDetail, PaymentItem?)>.self)
        
        viewModel.dataEvents.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(observer.events.isEmpty)
        MockAppState.current = .default
    }
    
    // Tests changes in the `alertBannerText` value.
    func testAlertBannerText() {
        // TODO: - Revisit this with more possibilities
        MockUser.current = MockUser(globalKeys: .restoreService, .catchUp, .avoidShutoff, .avoidShutoffExtended, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        // Catch Up and Restore Service don't apply to BGE, but the mock accounts still have past due amounts.
        let expectedValues: [String?] = [
            Environment.shared.opco == .bge ? "$200.00 of the total is due immediately." : "$200.00 of the total must be paid immediately to restore service. We cannot guarantee that your service will be reconnected same day.",
            (Environment.shared.opco == .bge) ? "$200.00 of the total is due immediately." : (Environment.shared.opco == .peco) ?  "$100.00 of the total must be paid immediately to catch up on your DPA.": "$100.00 of the total must be paid by 01/11/2019 to catch up on your DPA.",
            "$100.00 of the total must be paid immediately to avoid shutoff.",
            "$100.00 of the total must be paid by 01/09/2019 to avoid shutoff.",
            nil
        ]
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.alertBannerText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()

        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `totalAmountText` value after switching
    // through 5 different accounts, then refreshing 2 times.
    func testTotalAmountText() {
        MockUser.current = MockUser(globalKeys: .billCardNoDefaultPayment, .billCardWithDefaultPayment, .default, .credit, .billCardWithDefaultCcPayment)
        MockAccountService.loadAccountsSync()
        
        let expectedValues: [String] = [
            "$200.00",
            "$5,000.00",
            "--",
            Environment.shared.opco == .bge ? "$350.34" : "$0.00",
            "$435.32",
            "$435.32",
            "$435.32"
        ]
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        let refreshEventTimes = Array(MockUser.current.accounts.count..<expectedValues.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        simulateRefreshPulls(at: refreshEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.totalAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `totalAmountDescriptionText` value after switching
    // through different accounts.
    func testTotalAmountDescriptionText() {
        MockUser.current = MockUser(globalKeys: .pastDueEqual, .credit, .billCardWithDefaultCcPayment, .billNoDueDate)
        MockAccountService.loadAccountsSync()
        
        let expectedValues: [String] = [
            "Total Amount Due Immediately",
            "Total Amount Due By --",
            "Total Amount Due By 01/11/2019",
            "Total Amount Due By --"
        ]
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.totalAmountDescriptionText.map(\.string).drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `catchUpDisclaimerText` value after switching
    // through different accounts.
    func testCatchUpDisclaimerText() {
        MockUser.current = MockUser(globalKeys: .catchUp, .catchUpPastNetEqual, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        let expectedCurrencyValues: [String] = ["$5.00", "$7.45", "--"]
        let text = "You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill."
        let expectedValues = expectedCurrencyValues.map {
            String(format: text, $0)
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.catchUpDisclaimerText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `pastDueAmountText` value after switching
    // through different accounts.
    func testPastDueAmountText() {
        MockUser.current = MockUser(globalKeys: .catchUp, .catchUpPastEqual, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        let expectedValues: [String] = ["$200.00", "$200.00", "--"]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.pastDueAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests the `remainingBalanceDueText` value, which is only dependent on OpCo.
    func testRemainingBalanceDueText() {
        XCTAssertEqual(NSLocalizedString("Remaining Balance Due", comment: ""),
                       viewModel.remainingBalanceDueText)
    }
    
    // Tests changes in the `remainingBalanceDueAmountText` value after switching
    // through different accounts.
    func testRemainingBalanceDueAmountText() {
        MockUser.current = MockUser(globalKeys: .paymentPending, .paymentsPending, .billCardNoDefaultPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        let expectedValues: [String] = ["$100.00", "$0.00", "--", "$0.00"]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.remainingBalanceDueAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `paymentReceivedAmountText` value after switching
    // through different accounts.
    func testPaymentReceivedAmountText() {
        MockUser.current = MockUser(globalKeys: .thankYouForPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.paymentReceivedAmountText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, ["$200.00", "--"])
    }
    
    // Tests changes in the `paymentReceivedDateText` value after switching
    // through different accounts.
    func testPaymentReceivedDateText() {
        MockUser.current = MockUser(globalKeys: .thankYouForPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.paymentReceivedDateText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, ["Payment Date 01/11/2019", nil])
    }
    
    // Tests changes in the `hasBillBreakdownData` value after switching
    // through different accounts.
    func testHasBillBreakdownData() {
        MockUser.current = MockUser(globalKeys: .billBreakdown, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.hasBillBreakdownData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, [true, false])
    }
    
    // Tests changes in the `paymentStatusText` value after switching
    // through different accounts.
    func testPaymentStatusText() {
        MockUser.current = MockUser(globalKeys: .bgEasy, .autoPay, .scheduledPayment, .thankYouForPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        let firstExpectedValue: String?
        switch Environment.shared.opco {
        case .bge:
            firstExpectedValue = "You are enrolled in BGEasy"
        case .comEd, .peco:
            firstExpectedValue = nil
        }
        
        let expectedValues: [String?] = [
            firstExpectedValue,
            "You are enrolled in AutoPay",
            "Thank you for scheduling your $82.00 payment for 01/01/2019",
            "Thank you for $200.00 payment on 01/11/2019",
            nil
        ]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.paymentStatusText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `makePaymentScheduledPaymentAlertInfo` value after switching
    // through different accounts.
    func testMakePaymentScheduledPaymentAlertInfo() {
        MockUser.current = MockUser(globalKeys: .bgEasy, .autoPay, .scheduledPayment, .thankYouForPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        let bgEasyText = """
You are already enrolled in our BGEasy direct debit payment option. BGEasy withdrawals process on the due date of your bill from the bank account you originally submitted. You may make a one-time payment now, but it may result in duplicate payment processing. Do you want to continue with a one-time payment?
"""
        
        let autoPayText = """
You currently have automatic payments set up. To avoid a duplicate payment, please review your payment activity before proceeding. Would you like to continue making an additional payment?\n\nNote: If you recently enrolled in AutoPay and you have not yet received a new bill, you will need to submit a payment for your current bill if you have not already done so.
"""
        
        let scheduledPaymentText = """
You have a payment of $82.00 scheduled for 01/01/2019. To avoid a duplicate payment, please review your payment activity before proceeding. Would you like to continue making an additional payment?
"""
        
        let expectedValues: [(String?, String?)] = [
            Environment.shared.opco == .bge ? ("Existing Automatic Payment", bgEasyText) : (nil, nil),
            ("Existing Automatic Payment", autoPayText),
            ("Existing Scheduled Payment", scheduledPaymentText),
            (nil, nil),
            (nil, nil)
        ]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver((String?, String?, AccountDetail).self)
        viewModel.makePaymentScheduledPaymentAlertInfo.bind(to: observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        let observedEqualsExpected = !zip(observer.events, expectedEvents)
            .map {
                let isEqual = $0.0.value.element!.0 == $0.1.value.element!.0 &&
                    $0.0.value.element!.1 == $0.1.value.element!.1
                return isEqual
            }
            .contains(false)
        
        XCTAssert(observedEqualsExpected)
    }
    
    // Tests changes in the `makePaymentStatusTextTapRouting` value after switching
    // through different accounts.
    func testMakePaymentStatusTextTapRouting() {
        MockUser.current = MockUser(globalKeys: .bgEasy, .autoPay, .scheduledPayment, .paymentsPending, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        let expectedValues: [MakePaymentStatusTextRouting] = [
            .nowhere,
            .autoPay,
            .activity,
            .nowhere,
            .nowhere
        ]
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(MakePaymentStatusTextRouting.self)
        viewModel.makePaymentStatusTextTapRouting.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
}
