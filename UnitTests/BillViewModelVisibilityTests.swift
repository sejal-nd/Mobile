//
//  BillViewModelVisibilityTests.swift
//  Mobile
//
//  Created by Sam Francis on 2/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class BillViewModelVisibilityTests: BillViewModelTests {
    
    // Tests changes in the `showLoadedState` value after switching
    // through different accounts.
    func testShowLoadedState() {
        MockUser.current = MockUser(globalKeys: .default, .error, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Void.self)
        
        viewModel.showLoadedState.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.map { $0.time }, [0, 2])
    }
    
    // Tests changes in the `showAlertBanner` value after switching
    // through different accounts.
    func testShowAlertBanner() {
        MockUser.current = MockUser(globalKeys: .restoreService, .avoidShutoff, .default, .catchUp, .pastDue)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showAlertBanner.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let events = observer.events.reduce([Recorded<Event<Bool>>]()) { array, event in
            var newArray = array
            newArray.removeAll(where: { $0.time == event.time })
            newArray.append(event)
            return newArray
        }
        
        let expectedAlertBannerEvents = [true, true, false, true, true]
        
        XCTAssertRecordedElements(events, expectedAlertBannerEvents)
    }
    
    // Tests changes in the `showCatchUpDisclaimer` value after switching
    // through different accounts.
    func testShowCatchUpDisclaimer() {
        MockUser.current = MockUser(globalKeys: .restoreService, .avoidShutoff, .default, .catchUp, .pastDue)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showCatchUpDisclaimer.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedValues = [false, false, false, Environment.shared.opco == .comEd, false]
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `showPastDue` value after switching
    // through different accounts.
    func testShowPastDue() {
        MockUser.current = MockUser(globalKeys: .restoreService, .avoidShutoff, .default, .catchUp, .pastDue)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showPastDue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedPastDueValues = [true, true, false, true, true]
        XCTAssertRecordedElements(observer.events, expectedPastDueValues)
    }
    
    // Tests changes in the `showPendingPayment` value after switching
    // through different accounts.
    func testShowPendingPayment() {
        MockUser.current = MockUser(globalKeys: .paymentPending, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showPendingPayment.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `showRemainingBalanceDue` value after switching
    // through different accounts.
    func testShowRemainingBalanceDue() {
        MockUser.current = MockUser(globalKeys: .paymentPending, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showRemainingBalanceDue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `showPaymentReceived` value after switching
    // through different accounts.
    func testShowPaymentReceived() {
        MockUser.current = MockUser(globalKeys: .thankYouForPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showPaymentReceived.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(Recorded.next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showCreditScenario` value after switching
    // through different accounts.
    func testShowCreditScenario() {
        MockUser.current = MockUser(globalKeys: .credit, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [Environment.shared.opco == .bge, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showCreditScenario.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(Recorded.next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showAmountDueTooltip` value after switching
    // through different accounts.
    func testShowAmountDueTooltip() {
        XCTAssertEqual(viewModel.showAmountDueTooltip, Environment.shared.opco == .peco)
    }
    
    // Tests changes in the `hasBillBreakdownData` value after switching
    // through different accounts.
    func testHasBillBreakdownData() {
        MockUser.current = MockUser(globalKeys: .default, .billBreakdown)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [false, true]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.hasBillBreakdownData.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(Recorded.next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
    // Tests changes in the `showAutoPay` value after switching
    // through different accounts.
    func testShowAutoPay() {
        MockUser.current = MockUser(globalKeys: .autoPay, .bgEasy, .autoPayEligible, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, true, true, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showAutoPay.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(Recorded.next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showMakeAPaymentButton` value after switching
    // through different accounts.
    func testShowMakeAPaymentButton() {
        MockUser.current = MockUser(globalKeys: .billCardNoDefaultPayment, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, Environment.shared.opco == .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showMakeAPaymentButton.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(Recorded.next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showPaperless` value after switching
    // through different accounts.
    func testShowPaperless() {
        MockUser.current = MockUser(globalKeys: .default, .eBill, .eBillEligible, .finaledStatus)
        MockAccountService.loadAccountsSync()
        
        let expectedValues = [
            Environment.shared.opco != .bge, true, true, false
        ]
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showPaperless.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `showBudget` value after switching
    // through different accounts.
    func testShowBudget() {
        MockUser.current = MockUser(globalKeys: .budgetBill, .budgetBillEligible, .default)
        MockAccountService.loadAccountsSync()
        
        let switchAccountEventTimes = Array(0..<MockUser.current.accounts.count)
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, true, Environment.shared.opco == .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showBudget.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(Recorded.next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
}
