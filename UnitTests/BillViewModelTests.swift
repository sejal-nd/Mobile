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
    
}
