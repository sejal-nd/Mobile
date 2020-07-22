//
//  RegistrationViewModelTests.swift
//  BGEUnitTests
//
//  Created by Maurya, Adarsh on 23/06/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import XCTest

class RegistrationViewModelTests: XCTestCase {
    var viewModel: RegistrationViewModel!
       
       override func setUp() {
           viewModel = RegistrationViewModel(registrationService: MockRegistrationService(), authenticationService: MockAuthenticationService())
       }


       func testValidateAccountSuccess() {
        let asyncExpectation = expectation(description: "testValidateAccountSuccess")
        
        viewModel.phoneNumber.accept("1234567890")
        viewModel.identifierNumber.accept("2345")
        viewModel.validateAccount(onSuccess: {
            asyncExpectation.fulfill()
        }, onMultipleAccounts: {
            asyncExpectation.fulfill()
        }) { _,_ in
            XCTFail("Unexpected failure response")
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testValidateAccountFail() {
        let asyncExpectation = expectation(description: "testValidateAccountFail")
        
        viewModel.phoneNumber.accept("123")
        viewModel.identifierNumber.accept("234")
        
        viewModel.validateAccount(onSuccess: {
             XCTFail("Unexpected success response")
        }, onMultipleAccounts: {
            XCTFail("Unexpected success response")
        }) { _,_ in
            asyncExpectation.fulfill()
        }
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }

}
