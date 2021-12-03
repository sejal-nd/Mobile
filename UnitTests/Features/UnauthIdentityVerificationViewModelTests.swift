//
//  UnauthIdentityVerificationViewModelTests.swift
//  UnitTests
//
//  Created by RAMAITHANI on 09/11/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import XCTest
@testable import EUMobile

class UnauthIdentityVerificationViewModelTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInputFieldPhoneNumber() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        XCTAssertTrue(viewModel.isValidPhoneNumber(phoneNumber: "1234", inputString: "5"))
        XCTAssertFalse(viewModel.isValidPhoneNumber(phoneNumber: "123456789000", inputString: "5"))
    }

    func testInputFieldSSN() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        XCTAssertTrue(viewModel.isValidSSN(ssn: "123", inputString: "5"))
        XCTAssertFalse(viewModel.isValidSSN(ssn: "123456", inputString: "5"))
    }
    
    func testPhoneNumber() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        XCTAssertFalse(viewModel.isValidPhoneNumber(""))
        XCTAssertFalse(viewModel.isValidPhoneNumber("123"))
        XCTAssertFalse(viewModel.isValidPhoneNumber("12345678901234"))
        XCTAssertTrue(viewModel.isValidPhoneNumber("1234567890"))
    }

    func testSSN() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        XCTAssertFalse(viewModel.isValidSSN(""))
        XCTAssertFalse(viewModel.isValidSSN("123"))
        XCTAssertFalse(viewModel.isValidSSN("123456"))
        XCTAssertTrue(viewModel.isValidSSN("1234"))
    }

    func testValidation() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        viewModel.phoneNumber = ""
        viewModel.ssn = ""
        XCTAssertFalse(viewModel.validation())
        
        viewModel.phoneNumber = "1234"
        viewModel.ssn = ""
        XCTAssertFalse(viewModel.validation())

        viewModel.phoneNumber = "1234567890"
        viewModel.ssn = ""
        XCTAssertFalse(viewModel.validation())

        viewModel.phoneNumber = ""
        viewModel.ssn = "12"
        XCTAssertFalse(viewModel.validation())

        viewModel.phoneNumber = ""
        viewModel.ssn = "1234"
        XCTAssertFalse(viewModel.validation())

        viewModel.phoneNumber = "123456"
        viewModel.ssn = "1234"
        XCTAssertFalse(viewModel.validation())

        viewModel.phoneNumber = "1234567890"
        viewModel.ssn = "124"
        XCTAssertFalse(viewModel.validation())

        viewModel.phoneNumber = "1234567890"
        viewModel.ssn = "1234"
        XCTAssertTrue(viewModel.validation())
    }

    func testCommercialUser() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        KeychainController.default.set(NewMockDataKey.unauthCommercialUser.rawValue, forKey: .tokenKeychainKey)

        let expectation = expectation(description: "API Response Expectation")
        viewModel.loadAccounts {
            expectation.fulfill()
        } onError: { error in
            XCTAssertThrowsError(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 120, handler: nil)
        XCTAssertFalse(viewModel.isAccountResidential)
    }
    
    func testResidentialUser() throws {
        
        let viewModel = UnauthIdentityVerificationViewModel()
        KeychainController.default.set(NewMockDataKey.unauthResidentialUser.rawValue, forKey: .tokenKeychainKey)

        let expectation = expectation(description: "API Response Expectation")
        viewModel.loadAccounts {
            expectation.fulfill()
        } onError: { error in
            XCTAssertThrowsError(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 120, handler: nil)
        XCTAssertTrue(viewModel.isAccountResidential)
    }
}
