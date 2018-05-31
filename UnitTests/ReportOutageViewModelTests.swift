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
            expectedString = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", comment: "")
        case .comEd:
            expectedString = NSLocalizedString("To report a downed or sparking power line, please call 1-800-334-7661", comment: "")
        case .peco:
            expectedString = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
        XCTAssert(expectedString == viewModel.footerTextViewText, "Expected \"\(expectedString)\", got \"\(viewModel.footerTextViewText)\"")
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
    
    func testMeterPingGetPowerStatus() {
        let error = [
            "meterInfo": [
                "pingResult": false,
            ]
        ]
        let successWithVoltageCheck = [
            "meterInfo": [
                "preCheckSuccess": true,
                "pingResult": true,
                "voltageResult": true,
                "voltageReads": "proper"
            ]
        ]
        let successNoVoltageCheck = [
            "meterInfo": [
                "preCheckSuccess": true,
                "pingResult": true,
                "voltageResult": false,
                "voltageReads": "proper"
            ]
        ]
        
        viewModel.outageStatus = OutageStatus.from(error as NSDictionary)
        let expect1 = expectation(description: "async")
        viewModel.meterPingGetPowerStatus(onPowerVerified: { voltageCheck in
            XCTFail("Unexpected onPowerVerified response")
        }, onError: {
            expect1.fulfill()
        })
        
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error, "timeout")
        }
        
        viewModel.outageStatus = OutageStatus.from(successWithVoltageCheck as NSDictionary)
        let expect2 = expectation(description: "async")
        viewModel.meterPingGetPowerStatus(onPowerVerified: { voltageCheck in
            XCTAssert(voltageCheck, "Expected onPowerVerified(true)")
            expect2.fulfill()
        }, onError: {
            XCTFail("Unexpected onError response")
        })
        
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error, "timeout")
        }
        
        viewModel.outageStatus = OutageStatus.from(successNoVoltageCheck as NSDictionary)
        let expect3 = expectation(description: "async")
        viewModel.meterPingGetPowerStatus(onPowerVerified: { voltageCheck in
            XCTAssertFalse(voltageCheck, "Expected onPowerVerified(false)")
            expect3.fulfill()
        }, onError: {
            XCTFail("Unexpected onError response")
        })
        
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testMeterPingGetVoltageStatus() {
        let errorNoVoltageReads = [
            "meterInfo": [
                "pingResult": true,
                "voltageResult": true,
            ]
        ]
        let errorImproper = [
            "meterInfo": [
                "preCheckSuccess": true,
                "pingResult": true,
                "voltageResult": true,
                "voltageReads": "improper"
            ]
        ]
        let success = [
            "meterInfo": [
                "preCheckSuccess": true,
                "pingResult": true,
                "voltageResult": true,
                "voltageReads": "proper"
            ]
        ]
        
        viewModel.outageStatus = OutageStatus.from(errorNoVoltageReads as NSDictionary)
        let expect1 = expectation(description: "async")
        viewModel.meterPingGetVoltageStatus(onVoltageVerified: {
            XCTFail("Unexpected onVoltageVerified response")
        }, onError: {
            expect1.fulfill()
        })
        
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error, "timeout")
        }
        
        viewModel.outageStatus = OutageStatus.from(errorImproper as NSDictionary)
        let expect2 = expectation(description: "async")
        viewModel.meterPingGetVoltageStatus(onVoltageVerified: {
            XCTFail("Unexpected onVoltageVerified response")
        }, onError: {
            expect2.fulfill()
        })
        
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error, "timeout")
        }
        
        viewModel.outageStatus = OutageStatus.from(success as NSDictionary)
        let expect3 = expectation(description: "async")
        viewModel.meterPingGetVoltageStatus(onVoltageVerified: {
            expect3.fulfill()
        }, onError: {
            XCTFail("Unexpected onError response")
        })
        
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error, "timeout")
        }
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
