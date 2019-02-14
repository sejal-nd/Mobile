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
        viewModel = UsageViewModel(authService: MockAuthenticationService(), accountService: accountService, usageService: MockUsageService())
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
        XCTAssertEqual(trimmedEvents, [next(0, "JUL 01"), next(1, "2016")])
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
        ])
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
        
        XCTAssertEqual(observer.events, [next(0, "$220.00")])
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
        XCTAssertEqual(trimmedEvents, [next(0, "AUG 01"), next(1, "2017")])
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
        ])
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
        
        XCTAssertEqual(observer.events, [next(0, "$220.00")])
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
        XCTAssertEqual(trimmedEvents, [next(0, "AUG 01"), next(1, "2017")])
    }
    
    // MARK: Projection Bar Drivers
    
    func testProjectedCost() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "test-projectedCost")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "test-projectedCost", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true)]
        
        let observer = scheduler.createObserver(Double?.self)
        
        viewModel.projectedCost.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        if Environment.shared.opco != .comEd { // ComEd is electric only
            XCTAssertEqual(trimmedEvents, [next(0, 230), next(1, 182)])
        } else {
            XCTAssertEqual(trimmedEvents, [next(0, 230), next(1, 230)])
        }
    }
    
    func testProjectedUsage() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "test-projectedUsage")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "test-projectedUsage", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true)]
        
        let observer = scheduler.createObserver(Double?.self)
        
        viewModel.projectedUsage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        if Environment.shared.opco != .comEd { // ComEd is electric only
            XCTAssertEqual(trimmedEvents, [next(0, 230), next(1, 182)])
        } else {
            XCTAssertEqual(trimmedEvents, [next(0, 230), next(1, 230)])
        }
    }
    
    func testShouldShowProjectedBar() {
        // Just testing the basic case for coverage. Quality testing will be performed on the functions that this driver combines
        viewModel.showProjectedBar.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowProjectedBar should be false initially")
        }).disposed(by: disposeBag)
    }
    
    func testProjectedBarHeightConstraintValue() {
        let testAccounts = [
            Account(accountNumber: "test-noForecast-comparedHighest"),
            Account(accountNumber: "test-hasForecast-forecastHighest"),
            Account(accountNumber: "test-hasForecast-referenceHighest"),
            Account(accountNumber: "test-hasForecast-comparedHighest"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-noForecast-comparedHighest", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-forecastHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-referenceHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-hasForecast-comparedHighest", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(CGFloat.self)
        
        viewModel.projectedBarHeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, 0.0),
            next(1, 134.0),
            next(2, CGFloat(134.0 * (150 / 220))),
            next(3, CGFloat(134.0 * (150 / 220))),
        ])
    }
    
    func testProjectedBarDollarLabelText() {
        let testAccounts = [
            Account(accountNumber: "test-projectedCostAndUsage"),
            Account(accountNumber: "test-projectedCostAndUsageOpower"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-projectedCostAndUsage", premiseNumber: "1", serviceType: "ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-projectedCostAndUsageOpower", premiseNumber: "1", serviceType: "ELECTRIC", isModeledForOpower: true, isAMIAccount: true, isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.projectedBarDollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, "500 kWh"),
            next(1, "$220.00"),
        ])
    }
    
    func testProjectedBarDateLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "test-projectedDate")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "test-projectedDate", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.projectedBarDateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        if Environment.shared.opco != .comEd { // ComEd is electric only
            XCTAssertEqual(trimmedEvents, [next(0, "AUG 13"), next(1, "JUL 03")])
        } else {
            XCTAssertEqual(trimmedEvents, [next(0, "AUG 13"), next(1, "AUG 13")])
        }
    }
    
    // MARK: Projection Not Available Bar Drivers
    
    func testShowProjectionNotAvailableBar() {
        let testAccounts = [
            Account(accountNumber: "test-projection-lessThan7"),
            Account(accountNumber: "test-projection-moreThan7"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-projection-lessThan7", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-projection-moreThan7", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showProjectionNotAvailableBar.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3)]).subscribe(onNext: {
            if $0 % 2 != 0 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
            AccountsStore.shared.currentAccount = testAccounts[$0 % 2]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, true),
            next(1, false),
            next(2, true),
            next(3, false),
        ])
    }
    
    func testProjectionNotAvailableDaysRemainingText() {
        let testAccounts = [
            Account(accountNumber: "test-projection-sixDaysOut"),
            Account(accountNumber: "test-projection-threeDaysOut"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-projection-sixDaysOut", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "test-projection-threeDaysOut", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.projectionNotAvailableDaysRemainingText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3)]).subscribe(onNext: {
            if $0 % 2 != 0 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
            AccountsStore.shared.currentAccount = testAccounts[$0 % 2]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, "1 day"),
            next(1, "4 days"),
            next(2, "1 day"),
            next(3, "4 days"),
        ])
    }
    
    // MARK: Bar Description Box Drivers
    
    func testBarDescriptionDateLabelText() {
        let testAccounts = [
            Account(accountNumber: "comparedReferenceStartEndDate"),
            Account(accountNumber: "forecastStartEndDate"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "comparedReferenceStartEndDate", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true),
            AccountDetail(accountNumber: "forecastStartEndDate", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isAMIAccount: true, isResidential: true),
        ]
        AccountsStore.shared.currentAccount = testAccounts[0]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.barDescriptionDateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5), next(6, 6)]).subscribe(onNext: {
            if $0 <= 3 {
                AccountsStore.shared.currentAccount = testAccounts[0]
            } else {
                AccountsStore.shared.currentAccount = testAccounts[1]
            }
            if $0 == 0 || $0 == 1 {
                self.viewModel.setBarSelected(tag: 0)
                if $0 == 1 {
                    self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
                }
            } else if $0 == 2 {
                self.viewModel.setBarSelected(tag: 1)
            } else if $0 == 3 {
                self.viewModel.setBarSelected(tag: 2)
            } else if $0 == 4 || $0 == 5 {
                self.viewModel.setBarSelected(tag: 3)
                if $0 == 5 {
                    self.viewModel.electricGasSelectedSegmentIndex.value = 1
                }
            } else if $0 == 6 {
                self.viewModel.setBarSelected(tag: 4)
            }
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, "Previous Bill"), // Test case: No Data bar selected, Previous Bill selected
            next(1, "Last Year"), // Test case: No Data bar selected, Last Year selected
            next(2, "Aug 01, 2018 - Aug 31, 2018"), // Test case: Previous bar selected
            next(3, "Sep 02, 2018 - Oct 01, 2018"), // Test case: Current bar selected
            next(4, "May 23, 2018 - Jun 24, 2018"),  // Test case: Projected bar selected (electric)
            next(5, "May 23, 2018 - Jun 24, 2018"),  // Test case: Projected bar selected (gas)
            next(6, "Projection Not Available") // Test case: Projection not available selected
        ])
    }
    
    func testBarDescriptionAvgTempLabelText() {
        AccountsStore.shared.currentAccount = Account(accountNumber: "test-avgTemp")
        accountService.mockAccounts = [AccountsStore.shared.currentAccount]
        accountService.mockAccountDetails = [AccountDetail(accountNumber: "test-avgTemp", premiseNumber: "1", serviceType: "GAS/ELECTRIC", isResidential: true)]
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.barDescriptionAvgTempLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            if $0 == 0 {
                self.viewModel.setBarSelected(tag: 1)
                self.viewModel.fetchAllData()
            }
            if $0 == 1 {
                self.viewModel.setBarSelected(tag: 2)
            }
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [next(0, "Avg. Temp 89° F"), next(1, "Avg. Temp 62° F")])
    }
    
    // MARK: Up/Down Arrow Image Drivers
    
    func testBillPeriodArrowImage() {
        let testAccounts = [
            Account(accountNumber: "test-billPeriod-zeroCostDifference"),
            Account(accountNumber: "test-billPeriod-positiveCostDifference"),
            Account(accountNumber: "test-billPeriod-negativeCostDifference"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-billPeriod-zeroCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-billPeriod-positiveCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-billPeriod-negativeCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(UIImage?.self)
        
        viewModel.billPeriodArrowImage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, #imageLiteral(resourceName: "no_change_icon")),
            next(1, #imageLiteral(resourceName: "ic_billanalysis_positive")),
            next(2, #imageLiteral(resourceName: "ic_billanalysis_negative")),
        ])
    }
    
    func testWeatherArrowImage() {
        let testAccounts = [
            Account(accountNumber: "test-weather-zeroCostDifference"),
            Account(accountNumber: "test-weather-positiveCostDifference"),
            Account(accountNumber: "test-weather-negativeCostDifference"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-weather-zeroCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-weather-positiveCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-weather-negativeCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(UIImage?.self)
        
        viewModel.weatherArrowImage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, #imageLiteral(resourceName: "no_change_icon")),
            next(1, #imageLiteral(resourceName: "ic_billanalysis_positive")),
            next(2, #imageLiteral(resourceName: "ic_billanalysis_negative")),
        ])
    }
    
    func testOtherArrowImage() {
        let testAccounts = [
            Account(accountNumber: "test-other-zeroCostDifference"),
            Account(accountNumber: "test-other-positiveCostDifference"),
            Account(accountNumber: "test-other-negativeCostDifference"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-other-zeroCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-other-positiveCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-other-negativeCostDifference", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(UIImage?.self)
        
        viewModel.otherArrowImage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2)]).subscribe(onNext: {
            AccountsStore.shared.currentAccount = testAccounts[$0]
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, #imageLiteral(resourceName: "no_change_icon")),
            next(1, #imageLiteral(resourceName: "ic_billanalysis_positive")),
            next(2, #imageLiteral(resourceName: "ic_billanalysis_negative")),
        ])
    }
    
    // MARK: Likely Reasons Drivers
    
    func testLikelyReasonsLabelText() {
        let testAccounts = [
            Account(accountNumber: "test-likelyReasons-noData"),
            Account(accountNumber: "test-likelyReasons-aboutSame"),
            Account(accountNumber: "test-likelyReasons-greater"),
            Account(accountNumber: "test-likelyReasons-less"),
        ]
        let testAccountDetails = [
            AccountDetail(accountNumber: "test-likelyReasons-noData", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-likelyReasons-aboutSame", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-likelyReasons-greater", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true),
            AccountDetail(accountNumber: "test-likelyReasons-less", premiseNumber: "1", serviceType: "ELECTRIC", isResidential: true)
        ]
        accountService.mockAccounts = testAccounts
        accountService.mockAccountDetails = testAccountDetails
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.likelyReasonsLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5), next(6, 6)]).subscribe(onNext: {
            if $0 == 0 {
                AccountsStore.shared.currentAccount = testAccounts[0]
            } else if $0 == 1 {
                AccountsStore.shared.currentAccount = testAccounts[1]
            } else if $0 == 2 {
                AccountsStore.shared.currentAccount = testAccounts[1]
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
            } else if $0 == 3 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
                AccountsStore.shared.currentAccount = testAccounts[2]
            } else if $0 == 4 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
                AccountsStore.shared.currentAccount = testAccounts[2]
            } else if $0 == 5 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
                AccountsStore.shared.currentAccount = testAccounts[3]
            } else if $0 == 6 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
                AccountsStore.shared.currentAccount = testAccounts[3]
            }
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertEqual(trimmedEvents, [
            next(0, "Data not available to explain likely reasons for changes in your electric charges."),
            next(1, "Likely reasons your electric charges are about the same as your previous bill."),
            next(2, "Likely reasons your electric charges are about the same as last year."),
            next(3, "Likely reasons your electric charges are about $100.00 more than your previous bill."),
            next(4, "Likely reasons your electric charges are about $100.00 more than last year."),
            next(5, "Likely reasons your electric charges are about $100.00 less than your previous bill."),
            next(6, "Likely reasons your electric charges are about $100.00 less than last year."),
        ])
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
    
    func testSetBarSelected() {
        XCTAssert(viewModel.barGraphSelection.value.rawValue == 2, "Index 2 should be selected initially")
        
        viewModel.setBarSelected(tag: 3)
        XCTAssert(viewModel.barGraphSelection.value.rawValue == 3, "Index 3 should be selected")

        viewModel.setBarSelected(tag: 4)
        XCTAssert(viewModel.barGraphSelection.value.rawValue == 4, "Index 4 should be selected")
    }
    
    func testSetLikelyReasonSelected() {
        XCTAssert(viewModel.likelyReasonsSelection.value.rawValue == 0, "Index 0 should be selected initially")
        
        viewModel.setLikelyReasonSelected(tag: 1)
        XCTAssert(viewModel.likelyReasonsSelection.value.rawValue == 1, "Index 1 should be selected")
        
        viewModel.setLikelyReasonSelected(tag: 2)
        XCTAssert(viewModel.likelyReasonsSelection.value.rawValue == 2, "Index 2 should be selected")
    }
    
}
