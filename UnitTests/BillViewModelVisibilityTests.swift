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
    
    let alertBannerTestAccountDetails: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32), isCutOutNonPay: true),
            AccountDetail(billingInfo: BillingInfo(pastDueAmount: 32,
                                                   pastDueRemaining: 89,
                                                   disconnectNoticeArrears: 43),
                          isCutOutNonPay: true,
                          isCutOutIssued: true),
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32, amtDpaReinst: 42)),
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32, amtDpaReinst: 42),
                          isLowIncome: true),
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 42, pastDueAmount: 32))
        ]
    
    // Tests changes in the `showLoadedState` value after switching
    // through different accounts.
    func testShowLoadedState() {
        let accountDetail: [AccountDetail] = [
            AccountDetail(),
            AccountDetail(accountNumber: "failure"),
            AccountDetail()
        ]
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Void.self)
        
        viewModel.showLoadedState.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.map { $0.time }, [0, 2])
    }
    
    // Tests changes in the `showAlertBanner` value after switching
    // through different accounts.
    func testShowAlertBanner() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
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
        
        let expectedAlertBannerEvents = [Environment.shared.opco != .bge, true, false, false, true]
        
        XCTAssertRecordedElements(events, expectedAlertBannerEvents)
    }
    
    // Tests changes in the `showCatchUpDisclaimer` value after switching
    // through different accounts.
    func testShowCatchUpDisclaimer() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showCatchUpDisclaimer.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedCatchUpDisclaimerValues = [false, false, Environment.shared.opco == .comEd, false, false]
        let expectedCatchUpDisclaimerEvents = zip(switchAccountEventTimes, expectedCatchUpDisclaimerValues).map(next)
        XCTAssertEqual(observer.events, expectedCatchUpDisclaimerEvents)
    }
    
    // Tests changes in the `showPastDue` value after switching
    // through different accounts.
    func testShowPastDue() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showPastDue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedPastDueValues = [false, true, false, false, true]
        XCTAssertRecordedElements(observer.events, expectedPastDueValues)
    }
    
    // Tests changes in the `showTopContent` value after switching
    // through different accounts.
    func testShowTopContent() {
        let accountDetail: [AccountDetail] = [
            AccountDetail(),
            AccountDetail(accountNumber: "failure")
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showTopContent.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [next(0, false), next(0, false), next(0, true),
                              next(1, false), next(1, false), next(1, false)]
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showPendingPayment` value after switching
    // through different accounts.
    func testShowPendingPayment() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(pendingPayments:[PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
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
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(remainingBalanceDue: 3, pendingPayments: [PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail(billingInfo: BillingInfo(remainingBalanceDue: 3)),
            AccountDetail(billingInfo: BillingInfo(pendingPayments: [PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, false, false, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showRemainingBalanceDue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertRecordedElements(observer.events, expectedValues)
    }
    
    // Tests changes in the `showPaymentReceived` value after switching
    // through different accounts.
    func testShowPaymentReceived() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 0, lastPaymentAmount: 3)),
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 0, lastPaymentAmount: 0)),
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 8, lastPaymentAmount: 5)),
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 8, lastPaymentAmount: 0))
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, false, false, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showPaymentReceived.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showCredit` value after switching
    // through different accounts.
    func testShowCredit() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(netDueAmount: -3)),
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 4))
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [Environment.shared.opco == .bge, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showCredit.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showAmountDueTooltip` value after switching
    // through different accounts.
    func testShowAmountDueTooltip() {
        XCTAssertEqual(viewModel.showAmountDueTooltip, Environment.shared.opco == .peco)
    }
    
    // Tests changes in the `showBillBreakdownButton` value after switching
    // through different accounts.
    func testShowBillBreakdownButton() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(),
            AccountDetail(serviceType: "123"),
            AccountDetail(premiseNumber: "123", serviceType: ""),
            AccountDetail(premiseNumber: "123", serviceType: "", serInfo: SERInfo(controlGroupFlag: "CONTROL"),  isResidential: true),
            AccountDetail(premiseNumber: "123", serviceType: "", flagFinaled: true, isResidential: true),
            AccountDetail(premiseNumber: "123", serviceType: "fdasfds", isResidential: true),
            AccountDetail(premiseNumber: "123", serviceType: "GAS", isResidential: true),
            AccountDetail(premiseNumber: "123", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(premiseNumber: "123", serviceType: "GAS/ELECTRIC", isResidential: true)
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [false, false, false, false, false, false, true, true, true]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showBillBreakdownButton.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
    // Tests changes in the `showAutoPay` value after switching
    // through different accounts.
    func testShowAutoPay() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(isAutoPay: true),
            AccountDetail(isBGEasy: true),
            AccountDetail(isAutoPayEligible: true),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, true, true, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showAutoPay.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `enableMakeAPaymentButton` value after switching
    // through different accounts.
    func testEnableMakeAPaymentButton() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 4)),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, Environment.shared.opco == .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.enableMakeAPaymentButton.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
    // Tests changes in the `showPaperless` value after switching
    // through different accounts.
    func testShowPaperless() {
        let isResidential = [false, true, true, true, true]
        let isEBillEligible = [false, false, true, false, false]
        let isEBillEnrollment = [false, true, false, false, false]
        let status = [nil, nil, nil, "finaled", nil]
        let expectedValues = [
            Environment.shared.opco != .bge,
            true,
            true,
            false,
            false
        ]
        
        let switchAccountEventTimes = Array(0..<expectedValues.count)
        
        accountService.mockAccountDetails = (0..<expectedValues.count).map {
            AccountDetail(isEBillEnrollment: isEBillEnrollment[$0],
                          isEBillEligible: isEBillEligible[$0],
                          status: status[$0],
                          isResidential: isResidential[$0])
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showPaperless.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `showBudget` value after switching
    // through different accounts.
    func testShowBudget() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(isBudgetBill: true, isBudgetBillEligible: true),
            AccountDetail(isBudgetBill: true, isBudgetBillEligible: false),
            AccountDetail(isBudgetBill: false, isBudgetBillEligible: true),
            AccountDetail(isBudgetBill: false, isBudgetBillEligible: false)
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, true, true, Environment.shared.opco == .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.showBudget.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
}
