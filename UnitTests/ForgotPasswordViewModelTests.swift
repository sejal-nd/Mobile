//
//  ForgotPasswordViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 4/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class ForgotPasswordViewModelTests: XCTestCase {
    
    var viewModel: ForgotPasswordViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        viewModel = ForgotPasswordViewModel(authService: MockAuthenticationService())
    }
    
    func testSubmitButtonEnabled() {
        viewModel.username.accept("aa")
        viewModel.submitButtonEnabled.asObservable().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Username \"aa\" should result in an enabled submit button")
            }
        }).disposed(by: disposeBag)
        
        viewModel.username.accept("")
        viewModel.submitButtonEnabled.asObservable().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Username \"\" should result in a disabled submit button")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitForgotPasswordSuccess() {
        let asyncExpectation = expectation(description: "testSubmitForgotPasswordSuccess")
        
        viewModel.username.accept("aa")
        viewModel.submitForgotPassword(onSuccess: { 
            asyncExpectation.fulfill()
        }, onProfileNotFound: { message in
            XCTFail("Unexpected onProfileNotFound response")
        }, onError: { message in
            XCTFail("Unexpected error response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testSubmitForgotPasswordProfileNotFound() {
        let asyncExpectation = expectation(description: "testSubmitForgotPasswordProfileNotFound")
        
        viewModel.username.accept("error")
        viewModel.submitForgotPassword(onSuccess: {
            XCTFail("Unexpected success response")
        }, onProfileNotFound: { message in
            asyncExpectation.fulfill()
        }, onError: { message in
            XCTFail("Unexpected error response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
}
