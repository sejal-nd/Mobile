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
        ReportedOutagesStore.shared.clearStore()
    }
        
    func testGetOutageStatusSuccess() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: {
            // Pass
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testGetOutageStatusFailureFinaled() {
        MockUser.current = MockUser(globalKeys: .finaled)
        MockAccountService.loadAccountsSync()

        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagFinaled, "Account is not finaled")
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testGetOutageStatusFailureNoPay() {
        MockUser.current = MockUser(globalKeys: .noPay)
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagNoPay, "Account is not a cut for non-pay account")
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testGetOutageStatusFailureNoService() {
        MockUser.current = MockUser(globalKeys: .outageNonServiceAgreement)
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: {
            XCTAssert(self.viewModel.currentOutageStatus!.flagNonService, "Account is not a non-service agreement account")
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
    }
    
    
    func testEstimatedRestorationDateStringReportedOutage() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        let testEtr = Date.now
        let testEtrString = DateFormatter.outageOpcoDateFormatter.string(from: testEtr)
        
        reportViewModel.reportOutage(onSuccess: {
            XCTAssertEqual(self.viewModel.outageReportedDateString, "Reported \(testEtrString)")
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testReportedOutage() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        reportViewModel.reportOutage(onSuccess: {
            XCTAssertNotNil(self.viewModel.reportedOutage, "Expected a Reported Outage Result.")
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testEstimatedRestorationDateStringCurrentOutage() {
        MockUser.current = MockUser(globalKeys: .outagePowerOut)
        MockAccountService.loadAccountsSync()
        
        let testEtrStringBge = "04/10/2017 04:45 AM"
        let testEtrStringComed = "03:45 AM on 4/10/2017"
        let testEtrStringPeco = "4:45 AM EDT on 4/10/2017"
        
        viewModel.getOutageStatus(onSuccess: {
            switch Environment.shared.opco {
            case .bge:
                XCTAssertEqual(self.viewModel.estimatedRestorationDateString, testEtrStringBge)
            case .comEd:
                XCTAssertEqual(self.viewModel.estimatedRestorationDateString, testEtrStringComed)
            case .peco:
                XCTAssertEqual(self.viewModel.estimatedRestorationDateString, testEtrStringPeco)
            }
        }, onError: { _ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testOutageReportedDateStringNotReported() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        XCTAssertEqual(self.viewModel.outageReportedDateString, "Reported")
    }
    
    func testOutageReportedDateStringReported() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let mockOutageService = MockOutageService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService)
        
        let testDate = Date.now
        let testDateString = DateFormatter.outageOpcoDateFormatter.string(from: testDate)
        
        reportViewModel.reportOutage(onSuccess: {
            XCTAssertEqual(self.viewModel.outageReportedDateString, "Reported \(testDateString)")
        }, onError: {_ in
            XCTFail("Unexpected failure response")
        })
    }
    
    func testFooterTextViewText() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
            
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
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
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
        MockUser.current = MockUser(globalKeys: .finaled)
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: {
            let expectedString: String
            if Environment.shared.opco == .bge {
                expectedString = NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
            } else {
                expectedString = NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            }
            XCTAssertEqual(self.viewModel.accountNonPayFinaledMessage, expectedString)
        }, onError: { _ in
            XCTFail("Unexpected error response")
        })
    }
    
    func testAccountNonPay() {
        MockUser.current = MockUser(globalKeys: .noPay)
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: {
            let expectedString: String
            if Environment.shared.opco == .bge {
                expectedString = NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
            } else {
                expectedString =  NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
            XCTAssertEqual(self.viewModel.accountNonPayFinaledMessage, expectedString)
        }, onError: { _ in
            XCTFail("Unexpected error response")
        })
    }
}
