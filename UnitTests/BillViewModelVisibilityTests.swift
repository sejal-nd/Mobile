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
    
    // Tests changes in the `shouldShowAlertBanner` value after switching
    // through different accounts.
    func testShouldShowAlertBanner() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32), isCutOutNonPay: true),
            AccountDetail(billingInfo: BillingInfo(disconnectNoticeArrears: 43,
                                                   isDisconnectNotice: true),
                          isCutOutNonPay: true),
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32, amtDpaReinst: 42)),
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32, amtDpaReinst: 42),
                          isLowIncome: true)
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedTrackerValues = [false] + switchAccountEventTimes.flatMap { _ in [true, false] }
        
        let expectedRestoreServiceValues = [Environment.sharedInstance.opco != .bge, false, false, false]
        let expectedAvoidShutoffValues = [false, true, false, false]
        let expectedCatchUpAmountValues = [false, false, true, true]
        let expectedCatchUpDisclaimerValues = [false, false, Environment.sharedInstance.opco == .comEd, false]
        
        let trackerObserver = scheduler.createObserver(Bool.self)
        viewModel.switchAccountsTracker.asDriver().drive(trackerObserver).disposed(by: disposeBag)
        
        let restoreServiceObserver = scheduler.createObserver(Bool.self)
        viewModel.shouldShowRestoreService.drive(restoreServiceObserver).disposed(by: disposeBag)
        
        let avoidShutoffObserver = scheduler.createObserver(Bool.self)
        viewModel.shouldShowAvoidShutoff.drive(avoidShutoffObserver).disposed(by: disposeBag)
        
        let catchUpAmountObserver = scheduler.createObserver(Bool.self)
        viewModel.shouldShowCatchUpAmount.drive(catchUpAmountObserver).disposed(by: disposeBag)
        
        let catchUpDisclaimerObserver = scheduler.createObserver(Bool.self)
        viewModel.shouldShowCatchUpDisclaimer.drive(catchUpDisclaimerObserver).disposed(by: disposeBag)
        
        //TODO: Check these events
        let alertBannerObserver = scheduler.createObserver(Bool.self)
        viewModel.shouldShowAlertBanner.drive(alertBannerObserver).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedTrackerEvents = zip([0] + switchAccountEventTimes.flatMap { [$0, $0] },
                                        expectedTrackerValues).map(next)
        XCTAssertEqual(trackerObserver.events, expectedTrackerEvents)
        
        let expectedRestoreServiceEvents = zip(switchAccountEventTimes, expectedRestoreServiceValues).map(next)
        XCTAssertEqual(restoreServiceObserver.events, expectedRestoreServiceEvents)
        
        let expectedAvoidShutoffEvents = zip(switchAccountEventTimes, expectedAvoidShutoffValues).map(next)
        XCTAssertEqual(avoidShutoffObserver.events, expectedAvoidShutoffEvents)
        
        let expectedCatchupAmountEvents = zip(switchAccountEventTimes, expectedCatchUpAmountValues).map(next)
        XCTAssertEqual(catchUpAmountObserver.events, expectedCatchupAmountEvents)
        
        let expectedCatchUpDisclaimerEvents = zip(switchAccountEventTimes, expectedCatchUpDisclaimerValues).map(next)
        XCTAssertEqual(catchUpDisclaimerObserver.events, expectedCatchUpDisclaimerEvents)
    }
    
    // Tests changes in the `pendingPaymentAmountDueBoxesAlpha` value after switching
    // through different accounts.
    func testPendingPaymentAmountDueBoxesAlpha() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(pendingPayments: [PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues: [CGFloat] = [0.5, 1]
        
        let observer = scheduler.createObserver(CGFloat.self)
        viewModel.pendingPaymentAmountDueBoxesAlpha.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowPendingPayment` value after switching
    // through different accounts.
    func testShouldShowPendingPayment() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(pendingPayments: [PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowPendingPayment.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowRemainingBalanceDue` value after switching
    // through different accounts.
    func testShouldShowRemainingBalanceDue() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(remainingBalanceDue: 3,
                                                   pendingPayments: [PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail(billingInfo: BillingInfo(remainingBalanceDue: 3)),
            AccountDetail(billingInfo: BillingInfo(pendingPayments: [PaymentItem(amount: 5, date: Date(), status: .pending)])),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [Environment.sharedInstance.opco != .bge, false, false, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowRemainingBalanceDue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowBillIssued` value after switching
    // through different accounts.
    func testShouldShowBillIssued() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBillIssued.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowPaymentReceived` value after switching
    // through different accounts.
    func testShouldShowPaymentReceived() {
        
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
        viewModel.shouldShowPaymentReceived.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowCredit` value after switching
    // through different accounts.
    func testShouldShowCredit() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(netDueAmount: -3)),
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 4))
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [Environment.sharedInstance.opco == .bge, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowCredit.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowAmountDueTooltip` value after switching
    // through different accounts.
    func testShouldShowAmountDueTooltip() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(pastDueAmount: -3)),
            AccountDetail(billingInfo: BillingInfo(pastDueAmount: 4))
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [Environment.sharedInstance.opco == .peco, false]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowAmountDueTooltip.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowNeedHelpUnderstanding` value after switching
    // through different accounts.
    func testShouldShowNeedHelpUnderstanding() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(),
            AccountDetail(serviceType: ""),
            AccountDetail(premiseNumber: "", serviceType: ""),
            AccountDetail(premiseNumber: "", serviceType: "", serInfo: SERInfo(controlGroupFlag: "CONTROL"),  isResidential: true),
            AccountDetail(premiseNumber: "", serviceType: "", flagFinaled: true, isResidential: true),
            AccountDetail(premiseNumber: "", serviceType: "fdasfds", isResidential: true),
            AccountDetail(premiseNumber: "", serviceType: "GAS", isResidential: true),
            AccountDetail(premiseNumber: "", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(premiseNumber: "", serviceType: "GAS/ELECTRIC", isResidential: true)
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [false, false, false, false, false, false, true, true, true]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowNeedHelpUnderstanding.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
    // Tests changes in the `shouldShowAutoPay` value after switching
    // through different accounts.
    func testShouldShowAutoPay() {
        
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
        viewModel.shouldShowAutoPay.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldEnableMakeAPaymentButton` value after switching
    // through different accounts.
    func testShouldEnableMakeAPaymentButton() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(billingInfo: BillingInfo(netDueAmount: 4)),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, Environment.sharedInstance.opco == .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldEnableMakeAPaymentButton.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
    // Tests changes in the `shouldShowPaperless` value after switching
    // through different accounts.
    func testShouldShowPaperless() {
        let isResidential = [false, true, true, true, true]
        let isEBillEligible = [false, false, true, false, false]
        let isEBillEnrollment = [false, true, false, false, false]
        let status = [nil, nil, nil, "finaled", nil]
        let expectedValues = [
            Environment.sharedInstance.opco != .bge,
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
        viewModel.shouldShowPaperless.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `shouldShowBudget` value after switching
    // through different accounts.
    func testShouldShowBudget() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(isBudgetBill: true, isBudgetBillEligible: true),
            AccountDetail(isBudgetBill: true, isBudgetBillEligible: false),
            AccountDetail(isBudgetBill: false, isBudgetBillEligible: true),
            AccountDetail(isBudgetBill: false, isBudgetBillEligible: false)
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [true, true, true, Environment.sharedInstance.opco == .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowBudget.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        XCTAssertEqual(observer.events, expectedEvents)
        
    }
    
}
