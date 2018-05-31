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
        let asyncExpectation = expectation(description: "testGetOutageStatusSuccess")
        
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "1234567890", "address": "573 Elm Street"]))
        
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
        let asyncExpectation = expectation(description: "testGetOutageStatusSuccess")
        
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "80000000000", "address": "573 Elm Street"]))

        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagFinaled, "Account was not filed.")
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testGetOutageStatusFailureNoPay() {
        let asyncExpectation = expectation(description: "testGetOutageStatusSuccess")
        
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "70000000000", "address": "573 Elm Street"]))
        
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagNoPay)
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testGetOutageStatusFailureNoService() {
        let asyncExpectation = expectation(description: "testGetOutageStatusSuccess")
        
        AccountsStore.shared.currentAccount = Account.from(NSDictionary(dictionary: ["accountNumber": "60000000000", "address": "573 Elm Street"]))
        
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagNonService)
            asyncExpectation.fulfill()
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    
    func testEstimatedRestorationDateStringReportedOutage() {
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        let testEtr = Date()
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
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!
        
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
    
    func testClearReportedOutage() {
        // Clear the user defaults first (UI testing may interfere with this test)
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!
        
        let expect = expectation(description: "Test report outage expectation")
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        reportViewModel.reportOutage(onSuccess: {
            expect.fulfill()
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
        
        viewModel.clearReportedOutage()
        XCTAssertNil(self.viewModel.reportedOutage, "Reported outage was not empty after clearing")
        
        waitForExpectations(timeout: 5) { (error) in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testEstimatedRestorationDateStringCurrentOutage() {
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "9836621902", "address": "573 Elm Street"])!
        
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
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "5591032201", "address": "573 Elm Street"])!
        
        XCTAssert(self.viewModel.outageReportedDateString == "Reported", "Received \(self.viewModel.outageReportedDateString) instead of \"Reported\"")
    }
    
    func testOutageReportedDateStringReported() {
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "123456", "address": "573 Elm Street"])!
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        let testDate = Date()
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
            AccountsStore.shared.currentAccount = Account.from(["accountNumber": "5591032201", "address": "573 Elm Street"])!
            
            switch Environment.shared.opco {
            case .bge:
                return XCTAssert(self.viewModel.footerTextViewText == "To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", "BGE footer text was not returned. Recieved \(self.viewModel.footerTextViewText)")
            case .comEd:
                return XCTAssert(self.viewModel.footerTextViewText == "To report a downed or sparking power line, please call 1-800-334-7661", "ComEd footer text was not returned. Recieved \(self.viewModel.footerTextViewText)")
            case .peco:
                return XCTAssert(self.viewModel.footerTextViewText == "To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", "PECO footer text was not returned. Recieved \(self.viewModel.footerTextViewText)")}
    }
    
    func testGasOnlyMessage() {
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "5591032201", "address": "573 Elm Street"])!
        
        switch Environment.shared.opco {
        case .bge:
            return XCTAssert(self.viewModel.gasOnlyMessage == "We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency or a downed or sparking power line, please call 1-800-685-0123.", "BGE Gas Only message was not returned. Received \(self.viewModel.gasOnlyMessage)")
        case .peco:
            return XCTAssert(self.viewModel.gasOnlyMessage == "We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call 1-800-841-4141.", "PECO Gas Only message was not returned. Received \(self.viewModel.gasOnlyMessage)")
        default:
            return XCTAssert(self.viewModel.gasOnlyMessage == "We currently do not allow reporting of gas issues online but want to hear from you right away.", "Default Gas Only message was not returned. Received \(self.viewModel.gasOnlyMessage)")}
    }
    
    func testAccountFinaled() {
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "75395146464", "address": "573 Elm Street"])!
        
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
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "3216544560", "address": "573 Elm Street"])!
        
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
