//
//  ReportOutageViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 3/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class ReportOutageViewModelTests: XCTestCase {
    var viewModel: ReportOutageViewModel!
    
    let disposeBag = DisposeBag()
    
    override func setUp() {
        viewModel = ReportOutageViewModel(outageService: MockOutageService())
    }
    
    func testSubmitButtonEnabled() {
        viewModel.phoneNumber.value = "410-123-4567"
        viewModel.reportFormHidden.value = false
        viewModel.submitEnabled.asObservable().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitButtonDisabled() {
        viewModel.phoneNumber.value = ""
        viewModel.submitEnabled.asObservable().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Submit button should be disabled")
            }
        }).disposed(by: disposeBag)
    }
    
    func testReportOutageSuccess() {
        let asyncExpectation = expectation(description: "testReportOutageSuccess")
        
        AccountsStore.sharedInstance.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        
        viewModel.reportOutage(onSuccess: { 
            asyncExpectation.fulfill()
        }, onError: { error in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testReportOutageError() {
        let asyncExpectation = expectation(description: "testReportOutageError")
        
        // The mock outage service is configured to throw an error for account number "5591032201"
        AccountsStore.sharedInstance.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "5591032201", "address": "573 Elm Street"]))
        
        viewModel.reportOutage(onSuccess: {
            XCTFail("Unexpected success response")
        }, onError: { error in
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
}
