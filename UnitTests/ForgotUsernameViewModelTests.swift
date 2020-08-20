//
//  ForgotUsernameTests.swift
//  Mobile
//
//  Created by Marc Shilling on 4/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class ForgotUsernameViewModelTests: XCTestCase {
    
    var viewModel: ForgotUsernameViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        viewModel = ForgotUsernameViewModel(authService: MockAuthenticationService())
    }
    
    func testValidateAccountSuccess() {
        let asyncExpectation = expectation(description: "testValidateAccountSuccess")
        
        viewModel.validateAccount(onSuccess: { 
            asyncExpectation.fulfill()
        }, onNeedAccountNumber: { 
            XCTFail("Unexpected onNeedAccountNumber response")
        }, onError: { title, message in
            XCTFail("Unexpected error response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testValidateAccountFailure() {
        let asyncExpectation = expectation(description: "testValidateAccountFailure")
        
        viewModel.identifierNumber.accept("0000")
        viewModel.validateAccount(onSuccess: {
            XCTFail("Unexpected success response")
        }, onNeedAccountNumber: {
            XCTFail("Unexpected onNeedAccountNumber response")
        }, onError: { title, message in
            asyncExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testSubmitSecurityQuestionSuccess() {
        let asyncExpectation = expectation(description: "testSubmitSecurityQuestionSuccess")
        
        viewModel.securityQuestionAnswer.accept("exelon")
        viewModel.validateAccount(onSuccess: {
            self.viewModel.submitSecurityQuestionAnswer(onSuccess: { username in
                asyncExpectation.fulfill()
            }, onAnswerNoMatch: { message in
                XCTFail("Unexpected onAnswerNoMatch response")
            }, onError: { err in
                XCTFail("Unexpected error response")
            })
        }, onNeedAccountNumber:  {
            XCTFail("Unexpected onNeedAccountNumber response")
        }, onError: { title, message in
            XCTFail("Unexpected error response")
        })

    
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testSubmitSecurityQuestionAnswerNoMatch() {
        let asyncExpectation = expectation(description: "testSubmitSecurityQuestionAnswerNoMatch")
        
        viewModel.securityQuestionAnswer.accept("notexelon")
        viewModel.validateAccount(onSuccess: {
            self.viewModel.submitSecurityQuestionAnswer(onSuccess: { username in
                XCTFail("Unexpected success response")
            }, onAnswerNoMatch: { message in
                asyncExpectation.fulfill()
            }, onError: { err in
                XCTFail("Unexpected error response")
            })
        }, onNeedAccountNumber:  {
            XCTFail("Unexpected onNeedAccountNumber response")
        }, onError: { title, message in
            XCTFail("Unexpected error response")
        })
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testPhoneNumberHas10Digits() {
        viewModel.phoneNumber.accept("(410) 123-4206")
        viewModel.phoneNumberHasTenDigits.asObservable().single().subscribe(onNext: { valid in
            if !valid {
               XCTFail("Phone number \"(410) 123-4206\" should pass the 10 digit check")
            }
        }).disposed(by: disposeBag)
        
        viewModel.phoneNumber.accept("1234567890")
        viewModel.phoneNumberHasTenDigits.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Phone number \"1234567890\" should pass the 10 digit check")
            }
        }).disposed(by: disposeBag)
        
        viewModel.phoneNumber.accept("(410)--2513")
        viewModel.phoneNumberHasTenDigits.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Phone number \"(410)--2513\" should fail the 10 digit check")
            }
        }).disposed(by: disposeBag)
    }
    
    func testIdentifierHas4Digits() {
        viewModel.identifierNumber.accept("1234")
        viewModel.identifierHasFourDigits.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Identifier \"1234\" should pass the 4 digit check")
            }
        }).disposed(by: disposeBag)
        
        viewModel.identifierNumber.accept("123")
        viewModel.identifierHasFourDigits.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Identifier \"123\" should fail the 4 digit check")
            }
        }).disposed(by: disposeBag)
    }
    
    func testIdentifierIsNumericDigits() {
        viewModel.identifierNumber.accept("1234")
        viewModel.identifierIsNumeric.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Identifier \"1234\" should pass the isNumeric check")
            }
        }).disposed(by: disposeBag)
        
        viewModel.identifierNumber.accept("abcd")
        viewModel.identifierIsNumeric.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Identifier \"abcd\" should fail the isNumeric check")
            }
        }).disposed(by: disposeBag)
    }
    
    func testAccountNumberHasValidLength() {
        let accountNumber = Environment.shared.opco.isPHI ? "23850123112" : "2385012311"

        viewModel.accountNumber.accept(accountNumber)
        viewModel.accountNumberHasValidLength.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Account number \"\(accountNumber)\" should pass the \(accountNumber.count) digit check")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.accept("21254")
        viewModel.accountNumberHasValidLength.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Account number \"21254\" should fail the NotEmpty check")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSecurityQuestionAnswerNotEmpty() {
        viewModel.securityQuestionAnswer.accept("23850123")
        viewModel.securityQuestionAnswerNotEmpty.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Security question answer \"23850123\" should pass the NotEmpty check")
            }
        }).disposed(by: disposeBag)
        
        viewModel.securityQuestionAnswer.accept("")
        viewModel.securityQuestionAnswerNotEmpty.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Security question answer \"\" should fail the NotEmpty check")
            }
        }).disposed(by: disposeBag)
    }
    
}
