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
                                                   disconnectNoticeArrears: 43,
                                                   isDisconnectNotice: true),
                          isCutOutNonPay: true),
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32, amtDpaReinst: 42)),
            AccountDetail(billingInfo: BillingInfo(restorationAmount: 32, amtDpaReinst: 42),
                          isLowIncome: true),
            AccountDetail(billingInfo: BillingInfo(pastDueAmount: 32, pastDueRemaining: 20))
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
    
    // Tests changes in the `shouldShowAlertBanner` value after switching
    // through different accounts.
    func testShouldShowAlertBanner() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.shouldShowAlertBanner.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedAlertBannerEvents = [next(0, false), next(0, false), next(0, Environment.sharedInstance.opco != .bge),
                                         next(1, false), next(1, false), next(1, true),
                                         next(2, false), next(2, false), next(2, false),
                                         next(3, false), next(3, false), next(3, false),
                                         next(4, false), next(4, false), next(4, false)]
        XCTAssertEqual(observer.events, expectedAlertBannerEvents)
    }
    
    // Tests changes in the `shouldShowRestoreService` value after switching
    // through different accounts.
    func testShouldShowRestoreService() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.shouldShowRestoreService.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedRestoreServiceValues = [Environment.sharedInstance.opco != .bge, false, false, false, false]
        let expectedRestoreServiceEvents = zip(switchAccountEventTimes, expectedRestoreServiceValues).map(next)
        XCTAssertEqual(observer.events, expectedRestoreServiceEvents)
    }
    
    // Tests changes in the `shouldShowAvoidShutoff` value after switching
    // through different accounts.
    func testShouldShowAvoidShutoff() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.shouldShowAvoidShutoff.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedAvoidShutoffValues = [false, true, false, false, false]
        let expectedAvoidShutoffEvents = zip(switchAccountEventTimes, expectedAvoidShutoffValues).map(next)
        XCTAssertEqual(observer.events, expectedAvoidShutoffEvents)
    }
    
    // Tests changes in the `shouldShowCatchUpAmount` value after switching
    // through different accounts.
    func testShouldShowCatchUpAmount() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.shouldShowCatchUpAmount.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedCatchUpAmountValues = [false, false, true, true, false]
        let expectedCatchupAmountEvents = zip(switchAccountEventTimes, expectedCatchUpAmountValues).map(next)
        XCTAssertEqual(observer.events, expectedCatchupAmountEvents)
    }
    
    // Tests changes in the `shouldShowCatchUpDisclaimer` value after switching
    // through different accounts.
    func testShouldShowCatchUpDisclaimer() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.shouldShowCatchUpDisclaimer.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedCatchUpDisclaimerValues = [false, false, Environment.sharedInstance.opco == .comEd, false, false]
        let expectedCatchUpDisclaimerEvents = zip(switchAccountEventTimes, expectedCatchUpDisclaimerValues).map(next)
        XCTAssertEqual(observer.events, expectedCatchUpDisclaimerEvents)
    }
    
    // Tests changes in the `shouldShowPastDue` value after switching
    // through different accounts.
    func testShouldShowPastDue() {
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.shouldShowPastDue.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedPastDueValues = [false, false, false, false, true]
        let expectedPastDueEvents = zip(switchAccountEventTimes, expectedPastDueValues).map(next)
        XCTAssertEqual(observer.events, expectedPastDueEvents)
    }
    
    // Tests changes in the `shouldShowTopContent` value after switching
    // through different accounts.
    func testShouldShowTopContent() {
        
        let accountDetail: [AccountDetail] = [
            AccountDetail(),
            AccountDetail(accountNumber: "failure")
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowTopContent.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = [next(0, false), next(0, false), next(0, true),
                              next(1, false), next(1, false), next(1, false)]
        
        XCTAssertEqual(observer.events, expectedEvents)
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
    
    // Tests changes in the `shouldShowRemainingBalancePastDue` value after switching
    // through different accounts.
    func testShouldShowRemainingBalancePastDue() {
        
        let switchAccountEventTimes = Array(0..<alertBannerTestAccountDetails.count)
        
        accountService.mockAccountDetails = alertBannerTestAccountDetails
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let expectedValues = [false, false, false, false, Environment.sharedInstance.opco != .bge]
        
        let observer = scheduler.createObserver(Bool.self)
        viewModel.shouldShowRemainingBalancePastDue.drive(observer).disposed(by: disposeBag)
        
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
