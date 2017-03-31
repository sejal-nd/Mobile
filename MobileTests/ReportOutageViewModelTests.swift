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
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testSubmitButtonDisabled() {
        viewModel.phoneNumber.value = ""
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Submit button should be disabled")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testReportOutageSuccess() {
        let asyncExpectation = expectation(description: "testReportOutageSuccess")
        
        viewModel.account = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        
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
        viewModel.account = Account.from(NSDictionary(dictionary: ["accountNumber": "5591032201", "address": "573 Elm Street"]))
        
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
