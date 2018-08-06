//
//  UsageViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 10/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class UsageViewModelTests: XCTestCase {
    
    var viewModel: UsageViewModel!
    var scheduler: TestScheduler!
    var accountService: MockAccountService!
    
    let disposeBag = DisposeBag()
    
    override func setUp() {
        accountService = MockAccountService()
        viewModel = UsageViewModel(accountService: accountService, usageService: MockUsageService())
        scheduler = TestScheduler(initialClock: 0)
    }
    
    private func removeIntermediateEvents<T>(_ events: [Recorded<Event<T>>]) -> [Recorded<Event<T>>] {
        var trimmedArray: [Recorded<Event<T>>] = []
        let numEvents = events.count
        for i in 0..<numEvents {
            let event = events[i]
            let eventTime = event.time
            if i + 1 < numEvents {
                if events[i + 1].time == eventTime {
                    continue
                }
            }
            trimmedArray.append(event)
        }
        return trimmedArray
    }
    
    // MARK: No Data Bar Drivers

    func testNoDataBarDateLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "referenceEndDate")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "referenceEndDate", premiseNumber: "1", isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.noDataBarDateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [next(0, "JUL 01"), next(1, "2016")]);
    }
    
    // MARK: Previous Bar Drivers... PREVIOUS = COMPARED
    
    func testPreviousBarHeightConstraintValue() {
        let testAccounts = [
            Account(accountNumber: "testComparedMinHeight"),
            Account(accountNumber: "test-hasForecast-comparedHighest"),
            Account(accountNumber: "test-hasForecast-referenceHighest"),
            Account(accountNumber: "test-hasForecast-forecastHighest"),
            Account(accountNumber: "test-noForecast-comparedHighest"),
            Account(accountNumber: "test-noForecast-referenceHighest"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "testComparedMinHeight", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-comparedHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-referenceHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-forecastHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-noForecast-comparedHighest", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-noForecast-referenceHighest", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(CGFloat.self)
        
        viewModel.previousBarHeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, 3.0),
            next(1, 134.0),
            next(2, CGFloat(134.0 * (200 / 220))),
            next(3, CGFloat(134.0 * (200 / 230))),
            next(4, 134.0),
            next(5, CGFloat(134.0 * (200 / 220))),
        ]);
    }
    
    func testPreviousBarDollarLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "test-noForecast-comparedHighest")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "test-noForecast-comparedHighest", premiseNumber: "1", isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.previousBarDollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)]).subscribe(onNext: { _ in
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        XCTAssertEqual(observer.events, [next(0, "$220.00")]);
    }
    
    func testPreviousBarDateLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "comparedEndDate")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "comparedEndDate", premiseNumber: "1", isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.previousBarDateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [next(0, "AUG 01"), next(1, "2017")]);
    }
    
    // MARK: Current Bar Drivers...CURRENT = REFERENCE
    
    func testCurrentBarHeightConstraintValue() {
        let testAccounts = [
            Account(accountNumber: "testReferenceMinHeight"),
            Account(accountNumber: "test-hasForecast-comparedHighest"),
            Account(accountNumber: "test-hasForecast-referenceHighest"),
            Account(accountNumber: "test-hasForecast-forecastHighest"),
            Account(accountNumber: "test-noForecast-comparedHighest"),
            Account(accountNumber: "test-noForecast-referenceHighest"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "testReferenceMinHeight", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-comparedHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-referenceHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-forecastHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-noForecast-comparedHighest", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-noForecast-referenceHighest", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(CGFloat.self)
        
        viewModel.currentBarHeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, 3.0),
            next(1, CGFloat(134.0 * (200 / 220))),
            next(2, 134.0),
            next(3, CGFloat(134.0 * (220 / 230))),
            next(4, CGFloat(134.0 * (200 / 220))),
            next(5, 134.0),
        ]);
    }
    
    func testCurrentBarDollarLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "test-noForecast-referenceHighest")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "test-noForecast-referenceHighest", premiseNumber: "1", isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.currentBarDollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)]).subscribe(onNext: { _ in
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        XCTAssertEqual(observer.events, [next(0, "$220.00")]);
    }
    
    func testCurrentBarDateLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "referenceEndDate")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "referenceEndDate", premiseNumber: "1", isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.currentBarDateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [next(0, "AUG 01"), next(1, "2017")]);
    }
/*
    
    // MARK: Projection Bar Drivers
    
    func testProjectedCost() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        viewModel.electricForecast.value = BillForecast(projectedCost: 210)
        viewModel.gasForecast.value = BillForecast(projectedCost: 182)
        
        viewModel.projectedCost.asObservable().take(1).subscribe(onNext: { cost in
            if let expectedVal = cost {
                XCTAssertEqual(expectedVal, 210)
            } else {
                XCTFail("Unexpected nil")
            }
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.projectedCost.asObservable().take(1).subscribe(onNext: { cost in
                if let expectedVal = cost {
                    XCTAssertEqual(expectedVal, 182)
                } else {
                    XCTFail("Unexpected nil")
                }
            }).disposed(by: disposeBag)
        }
    }
    
    func testProjectedUsage() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        viewModel.electricForecast.value = BillForecast(projectedUsage: 210)
        viewModel.gasForecast.value = BillForecast(projectedUsage: 182)
        
        viewModel.projectedUsage.asObservable().take(1).subscribe(onNext: { cost in
            if let expectedVal = cost {
                XCTAssertEqual(expectedVal, 210)
            } else {
                XCTFail("Unexpected nil")
            }
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.projectedUsage.asObservable().take(1).subscribe(onNext: { cost in
                if let expectedVal = cost {
                    XCTAssertEqual(expectedVal, 182)
                } else {
                    XCTFail("Unexpected nil")
                }
            }).disposed(by: disposeBag)
        }
    }
    
    func testShouldShowProjectedBar() {
        // Just testing the basic case for coverage. Quality testing will be performed on the functions that this driver combines
        viewModel.showProjectedBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectedBar should be false initially")
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarHeightConstraintValue() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        
        // Test case: No projection
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssertEqual(val, 0)
        }).disposed(by: disposeBag)
        
        // Test case: Projected cost is highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 182))
        viewModel.electricForecast.value = BillForecast(projectedCost: 220)
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            XCTAssertEqual(val, 134)
        }).disposed(by: disposeBag)
        
        // Test case: Reference cost is highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 230), compared: UsageBillPeriod(charges: 182))
        viewModel.electricForecast.value = BillForecast(projectedCost: 220)
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (220 / 230))
            XCTAssertEqual(val, expectedVal)
        }).disposed(by: disposeBag)
        
        // Test case: Compared cost is highest
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 230), compared: UsageBillPeriod(charges: 240))
        viewModel.electricForecast.value = BillForecast(projectedCost: 220)
        viewModel.projectedBarHeightConstraintValue.asObservable().take(1).subscribe(onNext: { val in
            let expectedVal = CGFloat(134.0 * (220 / 240))
            XCTAssertEqual(val, expectedVal)
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarDollarLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.electricForecast.value = BillForecast(projectedUsage: 500, projectedCost: 220)
        
        // Test case: Account not modeled for OPower - show usage
        viewModel.projectedBarDollarLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "500 kWh")
        }).disposed(by: disposeBag)
        
        // Test case: Account IS modeled for OPower, show cost
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC", isModeledForOpower: true)
        viewModel.projectedBarDollarLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "$220.00")
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarDateLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        viewModel.electricForecast.value = BillForecast(billingEndDate: "2019-08-13")
        viewModel.gasForecast.value = BillForecast(billingEndDate: "2019-07-03")
        
        // Test case: Electric
        viewModel.projectedBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "AUG 13")
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            // Test case: Gas
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.projectedBarDateLabelText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssertEqual(text, "JUL 03")
            }).disposed(by: disposeBag)
        }
    }
    
    // MARK: Projection Not Available Bar Drivers
    
    func testShouldShowProjectionNotAvailableBar() {
        viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectionNotAvailableBar should be false when projectedCost is nil")
        }).disposed(by: disposeBag)
        
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let twoWeeksOut = Calendar.current.date(byAdding: .weekOfMonth, value: 2, to: today)!
        
        // Test case: Electric forecast with less than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: tomorrow))
        viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "shouldShowProjectionNotAvailableBar should be true when less than 7 days from billingStartDate")
        }).disposed(by: disposeBag)
        
        // Test case: Electric forecast with greater than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut))
        viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectionNotAvailableBar should be false when more than 7 days from billingStartDate")
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            // Test case: Gas forecast with less than 7 days since start
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: tomorrow))
            viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
                XCTAssert(shouldShow, "shouldShowProjectionNotAvailableBar should be true when less than 7 days from billingStartDate")
            }).disposed(by: disposeBag)
            
            // Test case: Gas forecast with greater than 7 days since start
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: twoWeeksOut))
            viewModel.shouldShowProjectionNotAvailableBar.asObservable().take(1).subscribe(onNext: { shouldShow in
                XCTAssertFalse(shouldShow, "shouldShowProjectionNotAvailableBar should be false when more than 7 days from billingStartDate")
            }).disposed(by: disposeBag)
        }
    }
    
    func testProjectionNotAvailableDaysRemainingText() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .opCo
        dateFormatter.timeZone = .opCo
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let sixDaysOut = Calendar.opCo.date(byAdding: .day, value: 6, to: today)!
        let threeDaysOut = Calendar.opCo.date(byAdding: .day, value: 3, to: today)!
        
        // Test case: Electric forecast with less than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut))
        viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "1 day")
        }).disposed(by: disposeBag)
        
        // Test case: Electric forecast with greater than 7 days since start
        viewModel.electricForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut))
        viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, "4 days")
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            // Test case: Gas forecast with less than 7 days since start
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: sixDaysOut))
            viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssertEqual(text, "1 day")
            }).disposed(by: disposeBag)
            
            // Test case: Gas forecast with greater than 7 days since start
            viewModel.gasForecast.value = BillForecast(billingStartDate: dateFormatter.string(from: threeDaysOut))
            viewModel.projectionNotAvailableDaysRemainingText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssertEqual(text, "4 days")
            }).disposed(by: disposeBag)
        }
    }
    
    // MARK: Bar Description Box Drivers
    
    func testBarDescriptionDateLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        
        // Test case: No Data bar selected, Previous Bill selected
        viewModel.setBarSelected(tag: 0)
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, NSLocalizedString("Previous Bill", comment: ""))
        }).disposed(by: disposeBag)
        
        // Test case: No Data bar selected, Last Year selected
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Last Year", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Previous bar selected
        viewModel.setBarSelected(tag: 1)
        viewModel.currentBillComparison.value = BillComparison(compared: UsageBillPeriod(startDate: "2018-08-01", endDate: "2018-08-31"))
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = "Aug 01, 2018 - Aug 31, 2018"
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Current bar selected
        viewModel.setBarSelected(tag: 2)
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(startDate: "2018-09-02", endDate: "2018-10-01"))
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = "Sep 02, 2018 - Oct 01, 2018"
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Projected bar selected (electric)
        viewModel.setBarSelected(tag: 3)
        viewModel.electricForecast.value = BillForecast(billingStartDate: "2018-05-23", billingEndDate: "2018-06-24")
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = "May 23, 2018 - Jun 24, 2018"
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            // Test case: Projected bar selected (gas)
            viewModel.gasForecast.value = BillForecast(billingStartDate: "2018-05-23", billingEndDate: "2018-06-24")
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
                let expectedText = "May 23, 2018 - Jun 24, 2018"
                XCTAssertEqual(text, expectedText)
            }).disposed(by: disposeBag)
        }
        
        // Test case: Projection not available selected
        viewModel.setBarSelected(tag: 4)
        viewModel.barDescriptionDateLabelText.asObservable().take(1).subscribe(onNext: { text in
            XCTAssertEqual(text, NSLocalizedString("Projection Not Available", comment: ""))
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionAvgTempLabelText() {
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(averageTemperature: 62), compared: UsageBillPeriod(averageTemperature: 89))
        
        // Test case: Previous bar selected
        viewModel.setBarSelected(tag: 1)
        viewModel.barDescriptionAvgTempLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Avg. Temp 89° F", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        viewModel.setBarSelected(tag: 2)
        viewModel.barDescriptionAvgTempLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Avg. Temp 62° F", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
    }
    
    func testBarDescriptionDetailLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
        
        // Test case: No Data bar selected, Previous Bill selected
        viewModel.setBarSelected(tag: 0)
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Not enough data available.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Previous bar selected
        viewModel.setBarSelected(tag: 1)
        viewModel.currentBillComparison.value = BillComparison(compared: UsageBillPeriod(charges: 200, usage: 1800, startDate: "2018-08-01", endDate: "2018-08-31"))
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was $200.00. You used an average of 60.00 kWh per day.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Previous bar selected - bill credit scenario
        viewModel.currentBillComparison.value = BillComparison(compared: UsageBillPeriod(charges: -20, usage: 1800, startDate: "2018-08-01", endDate: "2018-08-31"))
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("You had a bill credit of $20.00. You used an average of 60.00 kWh per day.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Current bar selected
        viewModel.setBarSelected(tag: 2)
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 182, usage: 1060, startDate: "2018-08-01", endDate: "2018-08-27"))
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was $182.00. You used an average of 40.77 kWh per day.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Current bar selected - bill credit scenario
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: -34.21, usage: 1060, startDate: "2018-08-01", endDate: "2018-08-27"))
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("You had a bill credit of $34.21. You used an average of 40.77 kWh per day.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Projected bar selected, modeled for OPower, electric
        viewModel.setBarSelected(tag: 3)
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC", isModeledForOpower: true)
        viewModel.electricGasSelectedSegmentIndex.value = 0
        viewModel.electricForecast.value = BillForecast(toDateCost: 7.29, projectedCost: 182)
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill is projected to be around $182.00. You've spent about $7.29 so far this bill period. This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Projected bar selected, not modeled for OPower, electric
        viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC", isModeledForOpower: false)
        viewModel.electricGasSelectedSegmentIndex.value = 0
        viewModel.electricForecast.value = BillForecast(toDateUsage: 13.72, projectedUsage: 172.2)
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("You are projected to use around 172 kWh. You've used about 13 kWh so far this bill period. This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        if Environment.shared.opco != .comEd { // ComEd is electric only
            // Test case: Projected bar selected, modeled for OPower, gas
            viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC", isModeledForOpower: true)
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.gasForecast.value = BillForecast(toDateCost: 160, projectedCost: 210)
            viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
                let expectedText = NSLocalizedString("Your bill is projected to be around $210.00. You've spent about $160.00 so far this bill period. This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                XCTAssertEqual(text, expectedText)
            }).disposed(by: disposeBag)
            
            // Test case: Projected bar selected, not modeled for OPower, gas
            viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC", isModeledForOpower: false)
            viewModel.electricGasSelectedSegmentIndex.value = 1
            viewModel.gasForecast.value = BillForecast(toDateUsage: 160, projectedUsage: 210)
            viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
                let expectedText = NSLocalizedString("You are projected to use around 210 kWh. You've used about 160 kWh so far this bill period. This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
                XCTAssertEqual(text, expectedText)
            }).disposed(by: disposeBag)
        }
        
        // Test case: Projection not available selected
        viewModel.setBarSelected(tag: 4)
        viewModel.barDescriptionDetailLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Data becomes available once you are more than 7 days into the billing cycle.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
    }
    
    // MARK: Up/Down Arrow Image Drivers
    
    func testBillPeriodArrowImage() {
        // Test case: Difference = 0
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.billPeriodArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "no_change_icon"))
        }).disposed(by: disposeBag)
        
        // Test case: Difference >= 1
        viewModel.currentBillComparison.value = BillComparison(billPeriodCostDifference: 100)
        viewModel.billPeriodArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "ic_billanalysis_positive"))
        }).disposed(by: disposeBag)
        
        // Test case: Difference <= 1
        viewModel.currentBillComparison.value = BillComparison(billPeriodCostDifference: -100)
        viewModel.billPeriodArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "ic_billanalysis_negative"))
        }).disposed(by: disposeBag)
    }
    
    func testWeatherArrowImage() {
        // Test case: Difference = 0
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.weatherArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "no_change_icon"))
        }).disposed(by: disposeBag)
        
        // Test case: Difference >= 1
        viewModel.currentBillComparison.value = BillComparison(weatherCostDifference: 100)
        viewModel.weatherArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "ic_billanalysis_positive"))
        }).disposed(by: disposeBag)
        
        // Test case: Difference <= 1
        viewModel.currentBillComparison.value = BillComparison(weatherCostDifference: -100)
        viewModel.weatherArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "ic_billanalysis_negative"))
        }).disposed(by: disposeBag)
    }
    
    func testOtherArrowImage() {
        // Test case: Difference = 0
        viewModel.currentBillComparison.value = BillComparison()
        viewModel.otherArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "no_change_icon"))
        }).disposed(by: disposeBag)
        
        // Test case: Difference >= 1
        viewModel.currentBillComparison.value = BillComparison(otherCostDifference: 100)
        viewModel.otherArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "ic_billanalysis_positive"))
        }).disposed(by: disposeBag)
        
        // Test case: Difference <= 1
        viewModel.currentBillComparison.value = BillComparison(otherCostDifference: -100)
        viewModel.otherArrowImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "ic_billanalysis_negative"))
        }).disposed(by: disposeBag)
    }
    
    // MARK: Likely Reasons Drivers
    
    func testLikelyReasonsLabelText() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        
        // Test case: Data not available
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Data not available to explain likely reasons for changes in your electric charges.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: About the same / Previous Bill
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 300), compared: UsageBillPeriod(charges: 300))
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Likely reasons your electric charges are about the same as your previous bill.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: About the same / Last Year
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Likely reasons your electric charges are about the same as last year.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Charges greater / Previous Bill
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 300), compared: UsageBillPeriod(charges: 200))
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Likely reasons your electric charges are about $100.00 more than your previous bill.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Charges greater / Last Year
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Likely reasons your electric charges are about $100.00 more than last year.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Charges less / Previous Bill
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(charges: 200), compared: UsageBillPeriod(charges: 300))
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Likely reasons your electric charges are about $100.00 less than your previous bill.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Charges less / Last Year
        viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
        viewModel.likelyReasonsLabelText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Likely reasons your electric charges are about $100.00 less than last year.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
    }
    
    func testLikelyReasonsDescriptionTitleText() {
        viewModel.setLikelyReasonSelected(tag: 0)
        viewModel.likelyReasonsDescriptionTitleText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Bill Period", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        viewModel.setLikelyReasonSelected(tag: 1)
        viewModel.likelyReasonsDescriptionTitleText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Weather", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        viewModel.setLikelyReasonSelected(tag: 2)
        viewModel.likelyReasonsDescriptionTitleText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Other", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
    }
    
    func testLikelyReasonsDescriptionDetailText() {
        viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
        
        // Test case: Bill period, about the same
        viewModel.setLikelyReasonSelected(tag: 0)
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), billPeriodCostDifference: 0)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("You spent about the same based on the number of days in your billing period.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Bill period, greater
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(startDate: "2018-08-01", endDate: "2018-09-01"), compared: UsageBillPeriod(startDate: "2018-07-01", endDate: "2018-07-25"), billPeriodCostDifference: 100)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was about $100.00 more. You used more electricity because this bill period was 7 days longer.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Bill period, less
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(startDate: "2018-08-01", endDate: "2018-08-23"), compared: UsageBillPeriod(startDate: "2018-07-01", endDate: "2018-07-25"), billPeriodCostDifference: -100)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was about $100.00 less. You used less electricity because this bill period was 2 days shorter.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Weather, about the same
        viewModel.setLikelyReasonSelected(tag: 1)
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), weatherCostDifference: 0)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("You spent about the same based on weather conditions.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Weather, greater
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), weatherCostDifference: 100)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was about $100.00 more. You used more electricity due to changes in weather.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Weather, less
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), weatherCostDifference: -100)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was about $100.00 less. You used less electricity due to changes in weather.", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Other, about the same
        viewModel.setLikelyReasonSelected(tag: 2)
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), otherCostDifference: 0)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("You spent about the same based on a variety reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate plans or cost of energy", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Other, greater
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), otherCostDifference: 100)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was about $100.00 more. Your charges increased based on how you used energy. Your bill may be different for a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate plans or cost of energy", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
        
        // Test case: Other, less
        viewModel.currentBillComparison.value = BillComparison(reference: UsageBillPeriod(), compared: UsageBillPeriod(), otherCostDifference: -100)
        viewModel.likelyReasonsDescriptionDetailText.asObservable().take(1).subscribe(onNext: { text in
            let expectedText = NSLocalizedString("Your bill was about $100.00 less. Your charges decreased based on how you used energy. Your bill may be different for a variety of reasons, including:\n• Number of people and amount of time spent in your home\n• New appliances or electronics\n• Differences in rate plans or cost of energy", comment: "")
            XCTAssertEqual(text, expectedText)
        }).disposed(by: disposeBag)
    }
    
    func testSetBarSelected() {
        for i in stride(from: 0, to: 5, by: 1) {
            if viewModel.barGraphSelectionStates.value[i].value {
                XCTFail("All variables should be false initially")
            }
        }
        
        viewModel.setBarSelected(tag: 2)
        XCTAssert(viewModel.barGraphSelectionStates.value[2].value, "Index 2's value should be true")
        for i in stride(from: 0, to: 5, by: 1) {
            if viewModel.barGraphSelectionStates.value[i].value && i != 2 {
                XCTFail("All variables should be false except index 2")
            }
        }
        
        viewModel.setBarSelected(tag: 4)
        XCTAssert(viewModel.barGraphSelectionStates.value[4].value, "Index 4's value should be true")
        for i in stride(from: 0, to: 5, by: 1) {
            if viewModel.barGraphSelectionStates.value[i].value && i != 4 {
                XCTFail("All variables should be false except index 4")
            }
        }
    }
    
    func testSetLikelyReasonSelected() {
        for i in stride(from: 0, to: 3, by: 1) {
            if viewModel.likelyReasonsSelectionStates.value[i].value && i != 0 {
                XCTFail("All variables should be false initially except index 0")
            }
        }
        
        viewModel.setLikelyReasonSelected(tag: 1)
        XCTAssert(viewModel.likelyReasonsSelectionStates.value[1].value, "Index 1's value should be true")
        for i in stride(from: 0, to: 3, by: 1) {
            if viewModel.likelyReasonsSelectionStates.value[i].value && i != 1 {
                XCTFail("All variables should be false except index 1")
            }
        }
        
        viewModel.setLikelyReasonSelected(tag: 2)
        XCTAssert(viewModel.likelyReasonsSelectionStates.value[2].value, "Index 2's value should be true")
        for i in stride(from: 0, to: 3, by: 1) {
            if viewModel.likelyReasonsSelectionStates.value[i].value && i != 2 {
                XCTFail("All variables should be false except index 2")
            }
        }
    }
    
    func testShouldShowElectricGasToggle() {
        if Environment.shared.opco == .comEd {
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for ComEd")
            }
        } else {
            viewModel.accountDetail = AccountDetail(serviceType: "GAS")
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for serviceType = GAS")
            }
            
            viewModel.accountDetail = AccountDetail(serviceType: "ELECTRIC")
            if viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should not be displayed for serviceType = ELECTRIC")
            }
            
            viewModel.accountDetail = AccountDetail(serviceType: "GAS/ELECTRIC")
            if !viewModel.shouldShowElectricGasToggle {
                XCTFail("Electric/Gas toggle should be displayed for serviceType = GAS/ELECTRIC")
            }
        }
        
    }
    
    func testShouldShowCurrentChargesSection() {
        viewModel.accountDetail = AccountDetail()
        if viewModel.shouldShowCurrentChargesSection {
            XCTFail("Current charges should not be displayed if deliveryCharges, supplyCharges, and taxesAndFees are not provided or total 0")
        }
        
        viewModel.accountDetail = AccountDetail(billingInfo: BillingInfo(deliveryCharges: 1))
        if !viewModel.shouldShowCurrentChargesSection {
            XCTFail("Current charges should be displayed if deliveryCharges, supplyCharges, and taxesAndFees total more than 0")
        }
    }
*/
}
