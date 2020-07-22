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

        viewModel.getOutageStatus(onSuccess: { _ in
            // Pass
        }) { _ in
            XCTFail("Unexpected failure response")
        }
    }
    
    func testGetOutageStatusFailureFinaled() {
        MockUser.current = MockUser(globalKeys: .finaled)
        MockAccountService.loadAccountsSync()

        viewModel.getOutageStatus(onSuccess: { outageStatus in
            XCTAssert(outageStatus.flagFinaled, "Account is not finaled")
        }) { _ in
            XCTFail("Unexpected failure response")
        }
    }
    
    func testGetOutageStatusFailureNoPay() {
        MockUser.current = MockUser(globalKeys: .noPay)
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: { outageStatus in
            XCTAssert(outageStatus.flagNoPay, "Account is not a cut for non-pay account")
        }) { _ in
            XCTFail("Unexpected failure response")
        }
    }
    
    func testGetOutageStatusFailureNoService() {
        MockUser.current = MockUser(globalKeys: .outageNonServiceAgreement)
        MockAccountService.loadAccountsSync()
        
        viewModel.getOutageStatus(onSuccess: { outageStatus in
            XCTAssert(outageStatus.flagNonService, "Account is not a non-service agreement account")
        }) { _ in
            XCTFail("Unexpected failure response")
        }
    }
    
    
    func testEstimatedRestorationDateStringReportedOutage() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let mockOutageService = MockOutageService()
        let mockAccountService = MockAccountService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService, accountService: mockAccountService)
        
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
        let mockAccountService = MockAccountService()
        viewModel = OutageViewModel(accountService: mockAccountService, outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService, accountService: mockAccountService)
        
        reportViewModel.reportOutage(onSuccess: {
            XCTAssertNotNil(self.viewModel.reportedOutage, "Expected a Reported Outage Result.")
        }, onError: {_ in
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
        let mockAccountService = MockAccountService()
        viewModel = OutageViewModel(accountService: MockAccountService(), outageService: mockOutageService, authService: MockAuthenticationService())
        let reportViewModel = ReportOutageViewModel(outageService: mockOutageService, accountService: mockAccountService)
        
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
            expectedString = "If you smell natural gas, leave the area immediately and call 1-800-685-0123 or 1-877-778-7798\n\nFor downed or sparking power lines, please call 1-800-685-0123 or 1-877-778-2222"
        case .comEd:
            expectedString = "To report a downed or sparking power line, please call 1-800-334-7661"
        case .peco:
            expectedString = "To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141"
        case .pepco:
            expectedString = "To report a downed or sparking power line, please call 1-877-737-2662"
        case .ace:
            expectedString = "To report a downed or sparking power line, please call 1-800-833-7476"
        case .delmarva:
            expectedString = "If you smell natural gas, leave the area immediately and call 302-454-0317\n To report a downed or sparking power line, please call 1-800-898-8042"
        }
        
        return XCTAssertEqual(self.viewModel.footerTextViewText.string, expectedString)
    }
}
