//
//  OutageViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 3/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.

import XCTest

class OutageViewModelTests: XCTestCase {
    
    var viewModel: OutageViewModel!
    
    override func setUp() {
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: MockOutageService(), authService: MockAuthenticationService())
    }
        
    func testGetOutageStatusSuccess() {
        MockUser.current = MockUser()
        MockAccountService.loadAccountsSync()
        
        let asyncExpectation = expectation(description: "testGetOutageStatusSuccess")
        viewModel.getOutageStatus(onSuccess: {
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testGetOutageStatusFailureFinaled() {
        MockUser.current = MockUser(globalKey: .finaled)
        MockAccountService.loadAccountsSync()

        let asyncExpectation = expectation(description: "testGetOutageStatusFailureFinaled")
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagFinaled, "Account is not finaled")
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testGetOutageStatusFailureNoPay() {
        MockUser.current = MockUser(globalKey: .noPay)
        MockAccountService.loadAccountsSync()
        
        let asyncExpectation = expectation(description: "testGetOutageStatusFailureNoPay")
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagNoPay, "Account is not a cut for non-pay account")
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testGetOutageStatusFailureNoService() {
        MockUser.current = MockUser(globalKey: .outageNonServiceAgreement)
        MockAccountService.loadAccountsSync()
        
        let asyncExpectation = expectation(description: "testGetOutageStatusFailureNoService")
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagNonService, "Account is not a non-service agreement account")
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    
    func testEstimatedRestorationDateStringReportedOutage() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        let testEtr = Date.now
        let testEtrString = DateFormatter.outageOpcoDateFormatter.string(from: testEtr)
        
        let expect = expectation(description: "Test report outage expectation")
        reportViewModel.reportOutage(onSuccess: {
            XCTAssert(self.viewModel.outageReportedDateString == "Reported \(testEtrString)", "Expected Reported \(testEtrString), got \(self.viewModel.outageReportedDateString)")
            expect.fulfill()
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testReportedOutage() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        let expect = expectation(description: "Test report outage expectation")
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        reportViewModel.reportOutage(onSuccess: {
            XCTAssertNotNil(self.viewModel.reportedOutage, "Expected a Reported Outage Result.")
            expect.fulfill()
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testEstimatedRestorationDateStringCurrentOutage() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "9836621902", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        let testEtrStringBge = "04/10/2017 03:45 AM"
        let testEtrStringComed = "03:45 AM on 4/10/2017"
        let testEtrStringPeco = "3:45 AM EDT on 4/10/2017"
        
        let expect = expectation(description: "Test Outage status expectation")
        viewModel.getOutageStatus(onSuccess: {
            if (Environment.shared.opco == .bge){
            XCTAssert(self.viewModel.estimatedRestorationDateString == testEtrStringBge, "Expected \(testEtrStringBge), received \(self.viewModel.estimatedRestorationDateString)")
                expect.fulfill()}
            else if (Environment.shared.opco == .comEd){
                XCTAssert(self.viewModel.estimatedRestorationDateString == testEtrStringComed, "Expected \(testEtrStringComed), received \(self.viewModel.estimatedRestorationDateString)")
                expect.fulfill()
            }
            else if (Environment.shared.opco == .peco){
                XCTAssert(self.viewModel.estimatedRestorationDateString == testEtrStringPeco, "Expected \(testEtrStringPeco), received \(self.viewModel.estimatedRestorationDateString)")
                expect.fulfill()
            }
        }, onError: {_ in
            XCTAssertNil("Unexpected failure response")
        })
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testOutageReportedDateStringNotReported() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "5591032201", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        XCTAssert(self.viewModel.outageReportedDateString == "Reported", "Received \(self.viewModel.outageReportedDateString) instead of \"Reported\"")
    }
    
    func testOutageReportedDateStringReported() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        let testDate = Date.now
        let testDateString = DateFormatter.outageOpcoDateFormatter.string(from: testDate)
        
        let expect = expectation(description: "Test report outage expectation")
        
        reportViewModel.reportOutage(onSuccess: {
            XCTAssert(self.viewModel.outageReportedDateString == "Reported \(testDateString)", "Expected Reported \(testDateString), got \(self.viewModel.outageReportedDateString)")
            expect.fulfill()
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testFooterTextViewText() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "5591032201", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
            
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = "If you smell natural gas, leave the area immediately and call 1-800-685-0123 or 1-800-778-7798\n\nFor downed or sparking power lines, please call 1-800-685-0123 or 1-877-778-2222"
        case .comEd:
            expectedString = "To report a downed or sparking power line, please call 1-800-334-7661"
        case .peco:
            expectedString = "To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141"
        }
        
        return XCTAssertEqual(self.viewModel.footerTextViewText.string, expectedString)
    }
    
    func testGasOnlyMessage() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "5591032201", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = "We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nIf you smell natural gas, leave the area immediately and call 1-800-685-0123 or 1-800-778-7798."
        case .peco:
            expectedString = "We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call 1-800-841-4141."
        case .comEd:
            expectedString = "We currently do not allow reporting of gas issues online but want to hear from you right away."
        }
        
        return XCTAssertEqual(self.viewModel.gasOnlyMessage.string, expectedString)
    }
    
    func testAccountFinaled() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "75395146464", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        viewModel.getOutageStatus(onSuccess: {
            let expectedString: String
            if Environment.shared.opco == .bge {
                expectedString = NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
            } else {
                expectedString = NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            }
            XCTAssert(self.viewModel.accountNonPayFinaledMessage == expectedString, "Finaled string was not returned. Received \"\(self.viewModel.accountNonPayFinaledMessage)\"")
        }, onError: { _ in
            XCTFail("Unexpected error response")
        })
    }
    
    func testAccountNonPay() {
        AccountsStore.shared.accounts = [Account.from(["accountNumber": "3216544560", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        
        viewModel.getOutageStatus(onSuccess: {
            let expectedString: String
            if Environment.shared.opco == .bge {
                expectedString = NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
            } else {
                expectedString =  NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
            XCTAssert(self.viewModel.accountNonPayFinaledMessage == expectedString, "Non pay string was not returned. Received \"\(self.viewModel.accountNonPayFinaledMessage)\"")
        }, onError: { _ in
            XCTFail("Unexpected error response")
        })
    }
}
