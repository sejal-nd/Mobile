//
//  AlertsViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AlertsViewModelTests: XCTestCase {
    
    var viewModel: AlertsViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!
        viewModel = AlertsViewModel(accountService: MockAccountService())
    }
    
    func testFetchDataSuccess() {
        viewModel.fetchData()
        
        let expect = expectation(description: "wait for callbacks")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            XCTAssertNotNil(self.viewModel.currentAccountDetail, "currentAccountDetail should be set")
            XCTAssertFalse(self.viewModel.isFetchingAccountDetail.value, "isFetchingAccountDetail should be false")
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testFetchDataErrors() {
        // Account detail failure
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "WRONG", "address": "573 Elm Street"])!
        viewModel = AlertsViewModel(accountService: MockAccountService())
        viewModel.fetchData()
        
        let expect1 = expectation(description: "wait for callbacks")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            XCTAssertNil(self.viewModel.currentAccountDetail, "currentAccountDetail should be nil")
            XCTAssertFalse(self.viewModel.isFetchingAccountDetail.value, "isFetchingAccountDetail should be false")
            XCTAssert(self.viewModel.isAccountDetailError.value, "isAccountDetailError should be true")
            expect1.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testShouldShowLoadingIndicator() {
        viewModel.isFetchingAccountDetail.value = true
        viewModel.shouldShowLoadingIndicator.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Loading indicator should show when Alerts tab is selected while fetching account detail")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowErrorLabel() {
        viewModel.isAccountDetailError.value = true
        viewModel.shouldShowErrorLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Error label should show when Alerts tab is selected and fetching account detail failed")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowAlertsTableView() {
        viewModel.isFetchingAccountDetail.value = false
        viewModel.isAccountDetailError.value = false
        viewModel.shouldShowAlertsTableView.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Alerts table view should show when Alerts tab is selected and we successfully fetched account detail")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowAlertsEmptyState() {
        viewModel.isFetchingAccountDetail.value = false
        viewModel.isAccountDetailError.value = false
        viewModel.shouldShowAlertsEmptyState.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Alerts empty should show when Alerts tab is selected and we successfully fetched 0 push notifications from account detail")
            }
        }).disposed(by: disposeBag)
    }

}
