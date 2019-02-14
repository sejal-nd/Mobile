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
    
    func testFooterTextViewText() {
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("If you smell natural gas, leave the area immediately and call 1-800-685-0123 or 1-877-778-7798\n\nFor downed or sparking power lines, please call 1-800-685-0123 or 1-877-778-2222", comment: "")
        case .comEd:
            expectedString = NSLocalizedString("To report a downed or sparking power line, please call 1-800-334-7661", comment: "")
        case .peco:
            expectedString = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
        
        XCTAssertEqual(expectedString, viewModel.footerTextViewText.string, "Expected \"\(expectedString)\", got \"\(viewModel.footerTextViewText.string)\"")
    }
    
    func testReportOutageSuccess() {
        let asyncExpectation = expectation(description: "testReportOutageSuccess")
        
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        
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
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "5591032201", "address": "573 Elm Street"]))
        
        viewModel.reportOutage(onSuccess: {
            XCTFail("Unexpected success response")
        }, onError: { error in
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testReportOutageAnonSuccess() {
        let asyncExpectation = expectation(description: "testReportOutageSuccess")
        
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        viewModel.outageStatus = OutageStatus.from(["accountNumber": "1234567890"])!
        viewModel.reportOutageAnon(onSuccess: { result in
            asyncExpectation.fulfill()
        }, onError: { error in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testReportOutageAnonError() {
        let asyncExpectation = expectation(description: "testReportOutageError")
        
        // The mock outage service is configured to throw an error for account number "5591032201"
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "5591032201", "address": "573 Elm Street"]))
        viewModel.outageStatus = OutageStatus.from(["accountNumber": "5591032201"])!
        viewModel.reportOutageAnon(onSuccess: { result in
            XCTFail("Unexpected success response")
        }, onError: { error in
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testShouldPingMeterActiveOutage() {
        if Environment.shared.opco != .comEd {
            XCTAssertFalse(viewModel.shouldPingMeter)
        } else {
            viewModel.outageStatus = OutageStatus.from(["accountNumber": "1234567890", "status": "ACTIVE", "smartMeterStatus": true])!
            XCTAssertFalse(viewModel.shouldPingMeter)
        }
    }
    
    func testShouldPingMeterNoSmartMeter() {
        if Environment.shared.opco != .comEd {
            XCTAssertFalse(viewModel.shouldPingMeter)
        } else {
            viewModel.outageStatus = OutageStatus.from(["accountNumber": "1234567890", "status": "NOT ACTIVE", "smartMeterStatus": false])!
            XCTAssertFalse(viewModel.shouldPingMeter)
        }
    }
    
    func testShouldPingMeterTrue() {
        if Environment.shared.opco != .comEd {
            XCTAssertFalse(viewModel.shouldPingMeter)
        } else {
            viewModel.outageStatus = OutageStatus.from(["accountNumber": "1234567890", "status": "NOT ACTIVE", "smartMeterStatus": true])!
            XCTAssertTrue(viewModel.shouldPingMeter)
        }
    }
    
    func testMeterPingSuccess() {
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        viewModel.meterPingGetStatus(onComplete: { meterPingInfo in
            XCTAssertTrue(meterPingInfo.pingResult)
            XCTAssertTrue(meterPingInfo.voltageResult)
            XCTAssertNotNil(meterPingInfo.voltageReads)
        }, onError: {
            XCTFail("unexpected error")
        })
    }

    func testPhoneNumberHasTenDigits() {
        viewModel.phoneNumberHasTenDigits.asObservable().take(1).subscribe(onNext: { has10 in
            XCTAssertFalse(has10, "phoneNumberHasTenDigits should be false initially")
        }).disposed(by: disposeBag)
        
        viewModel.phoneNumber.value = "10length10"
        viewModel.phoneNumberHasTenDigits.asObservable().take(1).subscribe(onNext: { has10 in
            XCTAssertFalse(has10, "phoneNumberHasTenDigits should be false for \"10length10\"")
        }).disposed(by: disposeBag)
        
        viewModel.phoneNumber.value = "1234567890"
        viewModel.phoneNumberHasTenDigits.asObservable().take(1).subscribe(onNext: { has10 in
            XCTAssert(has10, "phoneNumberHasTenDigits should be true for \"1234567890\"")
        }).disposed(by: disposeBag)
        
        viewModel.phoneNumber.value = "410-123-4567"
        viewModel.phoneNumberHasTenDigits.asObservable().take(1).subscribe(onNext: { has10 in
            XCTAssert(has10, "phoneNumberHasTenDigits should be true for \"410-123-4567\"")
        }).disposed(by: disposeBag)
    }
    
    
}
