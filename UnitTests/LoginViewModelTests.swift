//
//  LoginViewModelTests.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class LoginViewModelTests: XCTestCase {
    
    var viewModel: LoginViewModel!
    
    override func setUp() {
        viewModel = LoginViewModel(authService: MockAuthenticationService(), biometricsService: BiometricsService(), registrationService: MockRegistrationService())
    }
    
    func testSuccessfulLogin() {
        let asyncExpectation = expectation(description: "testSuccessfulLogin")
        
        viewModel.username.value = "valid@test.com"
        viewModel.password.value = "Password1"
        
        viewModel.performLogin(onSuccess: { _,_ in
            asyncExpectation.fulfill()
        }, onRegistrationNotComplete: {
            XCTFail("Unexpected onRegistrationNotComplete response")
        }, onError: { title, message in
            XCTFail("Unexpected failure response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testUnsuccessfulLogin() {
        let asyncExpectation = expectation(description: "testUnsuccessfulLogin")

        viewModel.username.value = "invalid@test.com"
        viewModel.password.value = "Password1"
        
        viewModel.performLogin(onSuccess: { _,_ in
            XCTFail("Unexpected success response")
        }, onRegistrationNotComplete: {
            XCTFail("Unexpected onRegistrationNotComplete response")
        }, onError: { title, message in
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
}
