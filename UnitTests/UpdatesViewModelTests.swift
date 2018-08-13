//
//  UpdatesViewModelTests.swift
//  BGEUnitTests
//
//  Created by Joseph Erlandson on 8/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class UpdatesViewModelTests: XCTestCase {
    
    var viewModel: UpdatesViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        viewModel = UpdatesViewModel(alertsService: MockAlertsService())
    }
    
    func testFetchDataSuccess() {
        viewModel.fetchData()
        
        let expect = expectation(description: "wait for callbacks")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            XCTAssertNotNil(self.viewModel.currentOpcoUpdates.value, "currentOpcoUpdates should be set")
            XCTAssertFalse(self.viewModel.isFetchingUpdates.value, "isFetchingUpdates should be false")
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testFetchDataErrors() {
        viewModel.fetchData(shouldSucceed: false)
        
        let expect1 = expectation(description: "wait for callbacks")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            XCTAssertNil(self.viewModel.currentOpcoUpdates.value, "currentOpcoUpdates should be nil")
            XCTAssertFalse(self.viewModel.isFetchingUpdates.value, "isFetchingUpdates should be false")
            XCTAssert(self.viewModel.isUpdatesError.value, "isUpdatesError should be true")
            expect1.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error, "timeout")
        }

    }
    
    func testShouldShowLoadingIndicator() {
        viewModel.isFetchingUpdates.value = true
        viewModel.shouldShowLoadingIndicator.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Loading indicator should show when Updates tab is selected while fetching updates")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowErrorLabel() {
        viewModel.isUpdatesError.value = true
        viewModel.shouldShowErrorLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Error label should show when Updates tab is selected and fetching updates failed")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowUpdatesTableView() {
        viewModel.isFetchingUpdates.value = false
        viewModel.isUpdatesError.value = false
        viewModel.shouldShowTableView.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Updates table view should show when Updates tab is selected and we successfully fetched updates")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowUpdatesEmptyState() {
        viewModel.isFetchingUpdates.value = false
        viewModel.isUpdatesError.value = false
        viewModel.currentOpcoUpdates.value = [OpcoUpdate]()
        viewModel.shouldShowUpdatesEmptyState.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Updates empty should show when Updates tab is selected and we successfully fetched 0 updates")
            }
        }).disposed(by: disposeBag)
    }
}
