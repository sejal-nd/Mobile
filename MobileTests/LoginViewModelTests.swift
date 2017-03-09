//
//  LoginViewModelTests.swift
//  Mobile
//
//  Created by Kenny Roethel on 3/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest

class LoginViewModelTests: XCTestCase {
    
    //Test that the view model correctly executes the login
    //functionality on the service.
    func testSuccessfulLogin() {
        let service = MockAuthenticationService()
        
        let viewModel = LoginViewModel(authService: service, fingerprintService: FingerprintService())
        
        viewModel.username.value = "valid@test.com"
        viewModel.password.value = "password"
        
        viewModel.performLogin(onSuccess: { 
            //Test Pass
        }) { (message) in
            print(message)
            XCTFail("Unexpected failure response")
        }
    }
    
    //Test that the view model correctly executes the login
    //functionality on the service.
    func testUnsuccessfulLogin() {
        let service = MockAuthenticationService()
        
        let viewModel = LoginViewModel(authService: service, fingerprintService: FingerprintService())
        
        viewModel.username.value = "invalid@test.com"
        viewModel.password.value = "password"
        
        viewModel.performLogin(onSuccess: {
            XCTFail("Unexpected success response")
        }) { (message) in
            //Test Pass
        }
    }
}
