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
        MockUser.current = MockUser(globalKey: .referenceEndDate)
        MockAccountService.loadAccountsSync()
        
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
        XCTAssertRecordedElements(trimmedEvents, ["JUL 01", "2016"])
    }
    
    // MARK: Previous Bar Drivers... PREVIOUS = COMPARED
    
    func testPreviousBarHeightConstraintValue() {
        MockUser.current = MockUser(globalKeys: .comparedMinHeight,
                                    .hasForecastComparedHighest,
                                    .hasForecastReferenceHighest,
                                    .hasForecastForecastHighest,
                                    .noForecastComparedHighest,
                                    .noForecastReferenceHighest)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(CGFloat.self)
        
        viewModel.previousBarHeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        let trimmedEvents = removeIntermediateEvents(observer.events)
        XCTAssertRecordedElements(trimmedEvents, [
            3.0,
            134.0,
            CGFloat(134.0 * (200 / 220)),
            CGFloat(134.0 * (200 / 230)),
            134.0,
            CGFloat(134.0 * (200 / 220))
            ])
    }
    
    func testPreviousBarDollarLabelText() {
        MockUser.current = MockUser(globalKey: .noForecastComparedHighest)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.previousBarDollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)]).subscribe(onNext: { _ in
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        XCTAssertEqual(observer.events, [next(0, "$220.00")])
    }
    
    func testPreviousBarDateLabelText() {
        MockUser.current = MockUser(globalKey: .comparedEndDate)
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKeys: .referenceMinHeight,
                                    .hasForecastComparedHighest,
                                    .hasForecastReferenceHighest,
                                    .hasForecastForecastHighest,
                                    .noForecastComparedHighest,
                                    .noForecastReferenceHighest)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(CGFloat.self)
        
        viewModel.currentBarHeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
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
        MockUser.current = MockUser(globalKey: .noForecastReferenceHighest)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.currentBarDollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0)]).subscribe(onNext: { _ in
            self.viewModel.fetchAllData()
        }).disposed(by: disposeBag)
        scheduler.start()
        
        XCTAssertEqual(observer.events, [next(0, "$220.00")])
    }
    
    func testCurrentBarDateLabelText() {
        MockUser.current = MockUser(globalKey: .referenceEndDate)
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKey: .projectedCost)
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKey: .projectedUsage)
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKeys: .noForecastComparedHighest,
                                    .hasForecastForecastHighest,
                                    .hasForecastReferenceHighest,
                                    .hasForecastComparedHighest)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(CGFloat.self)
        
        viewModel.projectedBarHeightConstraintValue.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
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
        MockUser.current = MockUser(globalKeys: .projectedCostAndUsage, .projectedCostAndUsageOpower)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.projectedBarDollarLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
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
        MockUser.current = MockUser(globalKey: .projectedDate)
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKeys: .projectionLessThan7, .projectionMoreThan7)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(Bool.self)
        
        viewModel.showProjectionNotAvailableBar.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3)]).subscribe(onNext: {
            if $0 % 2 != 0 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
            AccountsStore.shared.currentIndex = $0 % 2
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
        MockUser.current = MockUser(globalKeys: .projectionSixDaysOut, .projectionThreeDaysOut)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.projectionNotAvailableDaysRemainingText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3)]).subscribe(onNext: {
            if $0 % 2 != 0 {
                self.viewModel.electricGasSelectedSegmentIndex.value = 1
            }
            AccountsStore.shared.currentIndex = $0 % 2
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
        MockUser.current = MockUser(globalKeys: .comparedReferenceStartEndDate, .forecastStartEndDate)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.barDescriptionDateLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5), next(6, 6)]).subscribe(onNext: {
            if $0 <= 3 {
                AccountsStore.shared.currentIndex = 0
            } else {
                AccountsStore.shared.currentIndex = 1
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
        MockUser.current = MockUser(globalKey: .avgTemp)
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKeys: .zeroCostDifference, .positiveCostDifference, .negativeCostDifference)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(UIImage?.self)
        
        viewModel.billPeriodArrowImage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
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
        MockUser.current = MockUser(globalKeys: .zeroCostDifference, .positiveCostDifference, .negativeCostDifference)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(UIImage?.self)
        
        viewModel.weatherArrowImage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
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
        MockUser.current = MockUser(globalKeys: .zeroCostDifference, .positiveCostDifference, .negativeCostDifference)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(UIImage?.self)
        
        viewModel.otherArrowImage.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2)]).subscribe(onNext: {
            AccountsStore.shared.currentIndex = $0
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
        MockUser.current = MockUser(globalKeys: .likelyReasonsNoData, .likelyReasonsAboutSame, .likelyReasonsGreater, .likelyReasonsLess)
        MockAccountService.loadAccountsSync()
        
        let observer = scheduler.createObserver(String?.self)
        
        viewModel.likelyReasonsLabelText.drive(observer).disposed(by: disposeBag)
        
        scheduler.createHotObservable([next(0, 0), next(1, 1), next(2, 2), next(3, 3), next(4, 4), next(5, 5), next(6, 6)]).subscribe(onNext: {
            if $0 == 0 {
                AccountsStore.shared.currentIndex = 0
            } else if $0 == 1 {
                AccountsStore.shared.currentIndex = 1
            } else if $0 == 2 {
                AccountsStore.shared.currentIndex = 1
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
            } else if $0 == 3 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
                AccountsStore.shared.currentIndex = 2
            } else if $0 == 4 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
                AccountsStore.shared.currentIndex = 2
            } else if $0 == 5 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
                AccountsStore.shared.currentIndex = 3
            } else if $0 == 6 {
                self.viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
                AccountsStore.shared.currentIndex = 3
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
