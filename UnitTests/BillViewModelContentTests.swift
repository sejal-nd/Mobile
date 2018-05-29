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
        let accountDetail: [AccountDetail] = [
            AccountDetail(),
            AccountDetail(accountNumber: "failure"),
            AccountDetail()
        ]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(ServiceError?.self)
        
        viewModel.accountDetailError.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events.map { ($0.value.element!)!.serviceMessage! }, ["Account detail fetch failed."])
    }
    
    func testMaintenanceMode() {
        MockData.shared.username = "maintAllTabs"
        
        let accountDetail = [AccountDetail()]
        
        let switchAccountEventTimes = Array(0..<accountDetail.count)
        
        accountService.mockAccountDetails = accountDetail
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(Event<AccountDetail>.self)
        
        viewModel.accountDetailEvents.subscribe(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssert(observer.events.isEmpty)
        
        MockData.shared.username = ""
    }
    
    // Tests changes in the `alertBannerText` value.
    func testAlertBannerText() {
        let opco = Environment.sharedInstance.opco
        
        let restorationAmount: [Double?] = [9, nil, nil, nil, nil]
        let amtDpaReinst: [Double?] = [nil, nil, nil, nil, nil]
        let isCutOutNonPay = [true, false, false, false, false]
        
        let disconnectNoticeArrears: [Double?] = [nil, nil, 4, 6, nil]
        let isDisconnectNotice = [false, false, true, true, false]
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let dueByDate: [Date?] = [nil, nil, "02/12/2018", "02/12/2018", nil]
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        let turnOffNoticeExtendedDueDate: [Date?] = ["02/12/2018", "02/12/2018", "02/12/2018", nil, "02/12/2018"]
            .map {
                guard let string = $0 else { return nil }
                return dateFormatter.date(from: string)
        }
        
        let turnOffNoticeDueDate: [Date?] = ["02/12/2018", "02/12/2018", "02/12/2018", "02/10/2018", "02/12/2018"]
            .map { dateFormatter.date(from: $0) }
        
        let comEdPecoAvoidShutoffText1 = "Payment due to avoid shutoff is $4.00 due immediately."
        let comEdPecoAvoidShutoffText2 = "Payment due to avoid shutoff is $6.00 due immediately."
        let expectedValues: [String?] = [
            "Your service is off due to non-payment.",
            nil,
            opco == .bge ? "A payment of $4.00 is due by 02/12/2018" : comEdPecoAvoidShutoffText1,
            opco == .bge ? "Payment due to avoid service interruption is $6.00 due 02/10/2018." : comEdPecoAvoidShutoffText2,
            nil
        ]
        
        let switchAccountEventTimes = Array(0..<expectedValues.count)
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        accountService.mockAccountDetails = (0..<expectedValues.count).map { i -> AccountDetail in
            let billingInfo = BillingInfo(restorationAmount: restorationAmount[i],
                                          amtDpaReinst: amtDpaReinst[i],
                                          dueByDate: dueByDate[i],
                                          disconnectNoticeArrears: disconnectNoticeArrears[i],
                                          isDisconnectNotice: isDisconnectNotice[i],
                                          turnOffNoticeExtendedDueDate: turnOffNoticeExtendedDueDate[i],
                                          turnOffNoticeDueDate: turnOffNoticeDueDate[i])
            
            return AccountDetail(billingInfo: billingInfo,
                                 isCutOutNonPay: isCutOutNonPay[i])
        }
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.alertBannerText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
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
    
    // Tests changes in the `paymentStatusText` value after switching
    // through different accounts.
    func testPaymentStatusText() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let earlyDate = dateFormatter.date(from: "02/12/2015")!
        let lateDate = dateFormatter.date(from: "02/12/2017")!
        
        let isBGEasy = [true, false, false, false, false, false, false, false, false]
        let isAutoPay = [true, true, false, false, false, false, false, false, false]
        let paymentItems = [
            PaymentItem(amount: 4, status: .scheduled),
            PaymentItem(amount: 5000, status: .pending),
            PaymentItem(amount: 435.323, status: .pending),
            PaymentItem(amount: 4, date: earlyDate, status: .scheduled),
            PaymentItem(amount: -68.04, date: earlyDate, status: .scheduled),
            PaymentItem(amount: 0, date: nil, status: .pending),
            PaymentItem(amount: -52, date: Date(), status: .pending),
            PaymentItem(amount: -52, date: nil, status: .pending),
            PaymentItem(amount: -52, date: nil, status: .pending)
        ]
        let lastPaymentAmounts: [Double?] = [4, 5000, 435.323, -68.04, 585, 32, 432, 4, 0]
        let lastPaymentDates: [Date?] = [nil, nil, nil, nil, lateDate, earlyDate, earlyDate, lateDate, nil]
        let billDates: [Date?] = [nil, nil, nil, nil, earlyDate, lateDate, nil, nil, nil]
        
        let firstExpectedValue: String
        let thirdExpectedValue: String
        switch Environment.sharedInstance.opco {
        case .bge:
            firstExpectedValue = "You are enrolled in BGEasy"
            thirdExpectedValue = "You have a payment of $435.32 processing"
        case .comEd, .peco:
            firstExpectedValue = "You are enrolled in AutoPay"
            thirdExpectedValue = "You have a pending payment of $435.32"
        }
        
        let expectedValues: [String?] = [
            firstExpectedValue,
            "You are enrolled in AutoPay",
            thirdExpectedValue,
            "Thank you for scheduling your $4.00 payment for 02/12/2015",
            "Thank you for $585.00 payment on 02/12/2017",
            nil,
            nil,
            nil,
            nil
        ]
        
        let switchAccountEventTimes = Array(0..<isBGEasy.count)
        
        let range: CountableRange<Int> = 0..<isBGEasy.count
        accountService.mockAccountDetails = range.map { i -> AccountDetail in
            var scheduledPayment: PaymentItem? = nil
            var pendingPayments = [PaymentItem]()
            if paymentItems[i].status == .scheduled {
                scheduledPayment = paymentItems[i]
            } else {
                pendingPayments.append(paymentItems[i])
            }
            
            let billingInfo = BillingInfo(lastPaymentAmount: lastPaymentAmounts[i],
                                          lastPaymentDate: lastPaymentDates[i],
                                          billDate: billDates[i],
                                          scheduledPayment: scheduledPayment,
                                          pendingPayments: pendingPayments)
            
            return AccountDetail(billingInfo: billingInfo,
                                 isAutoPay: isAutoPay[i],
                                 isBGEasy: isBGEasy[i])
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.paymentStatusText.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        let observedEqualsExpected = !zip(observer.events, expectedEvents)
            .map {
                $0.0.value.element! == $0.1.value.element!
            }
            .contains(false)
        
        XCTAssert(observedEqualsExpected)
    }
    
    // Tests changes in the `makePaymentScheduledPaymentAlertInfo` value after switching
    // through different accounts.
    func testMakePaymentScheduledPaymentAlertInfo() {
        let bgEasyText = """
You are already enrolled in our BGEasy direct debit payment option. BGEasy withdrawals process on the due date of your bill from the bank account you originally submitted. You may make a one-time payment now, but it may result in duplicate payment processing. Do you want to continue with a one-time payment?
"""
        
        let autoPayText = """
You currently have automatic payments set up. To avoid a duplicate payment, please review your payment activity before proceeding. Would you like to continue making an additional payment?\n\nNote: If you recently enrolled in AutoPay and you have not yet received a new bill, you will need to submit a payment for your current bill if you have not already done so.
"""
        
        let scheduledPaymentText = """
You have a payment of $50.55 scheduled for 08/23/2018. To avoid a duplicate payment, please review your payment activity before proceeding. Would you like to continue making an additional payment?
"""
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let scheduledPaymentDate = dateFormatter.date(from: "08/23/2018")!
        
        let isBGEasy = [true, false, false, false, false]
        let isAutoPay = [true, true, false, false, false]
        let scheduledPaymentAmounts: [Double?] = [4, 5000, 50.55, -68.04, nil]
        let expectedValues: [(String?, String?)] = [
            ("Existing Automatic Payment", Environment.sharedInstance.opco == .bge ? bgEasyText : autoPayText),
            ("Existing Automatic Payment", autoPayText),
            ("Existing Scheduled Payment", scheduledPaymentText),
            (nil, nil),
            (nil, nil)
        ]
        
        let switchAccountEventTimes = Array(0..<isBGEasy.count)
        
        let range: CountableRange<Int> = 0..<isBGEasy.count
        accountService.mockAccountDetails = range.map { i -> AccountDetail in
            var scheduledPayment: PaymentItem? = nil
            if let scheduledPaymentAmount = scheduledPaymentAmounts[i] {
                scheduledPayment = PaymentItem(amount: scheduledPaymentAmount,
                                               date: scheduledPaymentDate,
                                               status: .scheduled)
            }
            
            let billingInfo = BillingInfo(scheduledPayment: scheduledPayment)
            
            return AccountDetail(billingInfo: billingInfo,
                                 isAutoPay: isAutoPay[i],
                                 isBGEasy: isBGEasy[i])
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver((String?, String?, AccountDetail).self)
        viewModel.makePaymentScheduledPaymentAlertInfo.bind(to: observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        let observedEqualsExpected = !zip(observer.events, expectedEvents)
            .map {
                $0.0.value.element!.0 == $0.1.value.element!.0 &&
                    $0.0.value.element!.1 == $0.1.value.element!.1
            }
            .contains(false)
        
        XCTAssert(observedEqualsExpected)
    }
    
    // Tests changes in the `makePaymentStatusTextTapRouting` value after switching
    // through different accounts.
    func testMakePaymentStatusTextTapRouting() {
        let isBGEasy = [true, false, false, false, false, false, false]
        let isAutoPay = [true, true, false, false, false, false, false]
        let paymentItems: [[PaymentItem]] = [
            [PaymentItem(amount: 4, status: .scheduled)],
            [PaymentItem(amount: 4, status: .scheduled), PaymentItem(amount: -3, status: .pending)],
            [PaymentItem(amount: 435.323, status: .scheduled)],
            [PaymentItem(amount: 4, status: .scheduled), PaymentItem(amount: -3, status: .pending)],
            [PaymentItem(amount: 4, status: .scheduled), PaymentItem(amount: 7, status: .pending)],
            [PaymentItem(amount: -5, status: .pending)],
            []
        ]
        
        let expectedValues: [MakePaymentStatusTextRouting] = [
            .nowhere,
            .autoPay,
            .activity,
            .activity,
            .nowhere,
            .nowhere,
            .nowhere
        ]
        
        let switchAccountEventTimes = Array(0..<expectedValues.count)
        
        let range: CountableRange<Int> = 0..<expectedValues.count
        accountService.mockAccountDetails = range.map { i -> AccountDetail in
            AccountDetail(billingInfo: BillingInfo(pendingPayments: paymentItems[i]),
                          isAutoPay: isAutoPay[i],
                          isBGEasy: isBGEasy[i])
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(MakePaymentStatusTextRouting.self)
        viewModel.makePaymentStatusTextTapRouting.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `autoPayButtonText` value after switching
    // through different accounts.
    func testAutoPayButtonText() {
        let isBGEasy = [true, false, true, false]
        let isAutoPay = [false, true, true, false]
        let expectedValues = [
            "AutoPay\nenrolled in BGEasy",
            "AutoPay\nenrolled",
            "AutoPay\nenrolled in BGEasy",
            "Would you like to enroll in AutoPay?"
        ]
        
        let switchAccountEventTimes = Array(0..<expectedValues.count)
        
        accountService.mockAccountDetails = zip(isBGEasy, isAutoPay).map {
            AccountDetail(isAutoPay: $0.1, isBGEasy: $0.0)
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.autoPayButtonText.map { $0.string }.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
    // Tests changes in the `paperlessButtonText` value after switching
    // through different accounts.
    func testPaperlessButtonText() {
        let isResidential = [false, true, true, true, true]
        let isEBillEligible = [false, false, true, false, false]
        let isEBillEnrollment = [false, true, false, false, false]
        let status = [nil, nil, nil, "finaled", nil]
        let expectedValues = [
            Environment.sharedInstance.opco == .bge ? nil : "Would you like to enroll in Paperless eBill?",
            "Paperless eBill\nenrolled",
            "Would you like to enroll in Paperless eBill?",
            nil,
            nil
        ]
        
        let switchAccountEventTimes = Array(0..<expectedValues.count)
        
        accountService.mockAccountDetails = (0..<expectedValues.count).map {
            AccountDetail(isEBillEnrollment: isEBillEnrollment[$0],
                          isEBillEligible: isEBillEligible[$0],
                          status: status[$0],
                          isResidential: isResidential[$0])
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String?.self)
        viewModel.paperlessButtonText.map { $0?.string }.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        let observedEqualsExpected = !zip(observer.events, expectedEvents)
            .map { $0.0.value.element! == $0.1.value.element! }
            .contains(false)
        
        XCTAssert(observedEqualsExpected)
    }
    
    // Tests changes in the `budgetButtonText` value after switching
    // through different accounts.
    func testBudgetButtonText() {
        let isBudgetBillEnrollment = [true, false]
        let expectedValues = [
            "Budget Billing\nenrolled",
            "Would you like to enroll in Budget Billing?"
        ]
        
        let switchAccountEventTimes = Array(0..<expectedValues.count)
        
        accountService.mockAccountDetails = isBudgetBillEnrollment.map {
            AccountDetail(isBudgetBill: $0)
        }
        
        simulateAccountSwitches(at: switchAccountEventTimes)
        
        let observer = scheduler.createObserver(String.self)
        viewModel.budgetButtonText.map { $0.string }.drive(observer).disposed(by: disposeBag)
        
        scheduler.start()
        
        let expectedEvents = zip(switchAccountEventTimes, expectedValues).map(next)
        
        XCTAssertEqual(observer.events, expectedEvents)
    }
    
}
