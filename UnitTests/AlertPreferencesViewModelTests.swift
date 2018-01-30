//
//  AlertPreferencesViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AlertPreferencesViewModelTests: XCTestCase {
    
    var viewModel: AlertPreferencesViewModel!
    let disposeBag = DisposeBag()
    
    func testShouldEnrollPaperlessEBill() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
        if Environment.sharedInstance.opco == .bge {
            XCTAssertFalse(viewModel.shouldEnrollPaperlessEBill, "shouldEnrollPaperlessEBill should always be false for BGE users")
        } else {
            viewModel.billReady.value = true
            XCTAssert(viewModel.shouldEnrollPaperlessEBill, "shouldEnrollPaperlessEBill should be true when initialBillReadyValue = false and billReady = true")
        }
    }
    
    func testShouldUnenrollPaperlessEBill() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
        if Environment.sharedInstance.opco == .bge {
            XCTAssertFalse(viewModel.shouldUnenrollPaperlessEBill, "shouldUnenrollPaperlessEBill should always be false for BGE users")
        } else {
            viewModel.initialBillReadyValue = true
            XCTAssert(viewModel.shouldUnenrollPaperlessEBill, "shouldUnenrollPaperlessEBill should be true when initialBillReadyValue = true and billReady = false")
        }
    }
    
    func testFetchData() {
        if Environment.sharedInstance.opco == .bge {
            viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
            viewModel.accountDetail = AccountDetail()
            
            let expect = expectation(description: "callback")
            viewModel.fetchData(onCompletion: {
                // Assert that all our view model vars were set from the Mock AlertPreferences object
                XCTAssert(self.viewModel.outage.value)
                XCTAssertFalse(self.viewModel.scheduledMaint.value)
                XCTAssert(self.viewModel.severeWeather.value)
                XCTAssertFalse(self.viewModel.billReady.value)
                XCTAssert(self.viewModel.paymentDue.value)
                XCTAssert(self.viewModel.paymentDueDaysBefore.value == 99)
                XCTAssert(self.viewModel.budgetBilling.value)
                XCTAssertFalse(self.viewModel.forYourInfo.value)
                expect.fulfill()
            })
            
            waitForExpectations(timeout: 2, handler: { error in
                XCTAssertNil(error, "timeout")
            })
        }
    }
    
    func testShouldShowContent() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
        viewModel.isFetching.value = false
        viewModel.isError.value = false
        viewModel.shouldShowContent.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Content should show when fetch is complete without error")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSaveButtonEnabled() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(), billService: MockBillService())
        viewModel.isFetching.value = false
        viewModel.isError.value = false
        viewModel.userChangedPrefs.value = true
        viewModel.saveButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Save button should be enabled")
            }
        }).disposed(by: disposeBag)
    }
}
