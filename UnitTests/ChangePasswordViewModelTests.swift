//
//  ChangePasswordTests.swift
//  Mobile
//
//  Created by Marc Shilling on 3/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class ChangePasswordTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    
    let userDefaultsSuiteName = "MobileTestsUserDefaults"
    var userDefaults: UserDefaults?
    var viewModel: ChangePasswordViewModel!
    
    override func setUp() {
        UserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        
        viewModel = ChangePasswordViewModel(userDefaults: userDefaults!, authService: MockAuthenticationService(), biometricsService: BiometricsService())
    }

    func testTooFewCharacterCount() {
        viewModel.newPassword.accept("abc")
        
        viewModel.characterCountValid.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abc\" should result in an invalid character count")
            }
        }).disposed(by: disposeBag)
    }
    
    func testTooManyCharacterCount() {
        viewModel.newPassword.accept("abcdefghijklmnopqrstuvwxzy")
        
        viewModel.characterCountValid.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abcdefghijklmnopqrstuvwxzy\" should result in an invalid character count")
            }
        }).disposed(by: disposeBag)
    }
    
    func testWhitespaceCharacterCount() {
        viewModel.newPassword.accept("abc       d")
        
        viewModel.characterCountValid.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abc       d\" (with whitespace) should result in an invalid character count")
            }
        }).disposed(by: disposeBag)
    }
    
    func testValidCharacterCount() {
        viewModel.newPassword.accept("abcdefgh")
        
        viewModel.characterCountValid.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Password \"abcdefgh\" should result in a valid character count")
            }
        }).disposed(by: disposeBag)
    }
    
    func testMissingUppercaseLetter() {
        viewModel.newPassword.accept("abcdefgh")
        
        viewModel.containsUppercaseLetter.asObservable().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcdefgh\" should not pass the uppercase letter requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testContainsUppercaseLetter() {
        viewModel.newPassword.accept("Abcdefgh")
        
        viewModel.containsUppercaseLetter.asObservable().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"Abcdefgh\" should pass the uppercase letter requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testMissingLowercaseLetter() {
        viewModel.newPassword.accept("ABCDEFGH")
        
        viewModel.containsLowercaseLetter.asObservable().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"ABCDEFGH\" should not pass the lowercase letter requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testContainsLowercaseLetter() {
        viewModel.newPassword.accept("aBCDEFGH")
        
        viewModel.containsLowercaseLetter.asObservable().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"aBCDEFGH\" should pass the lowercase letter requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testMissingNumber() {
        viewModel.newPassword.accept("abcdefgh")
        
        viewModel.containsNumber.asObservable().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcdefgh\" should not pass the number requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testContainsNumber() {
        viewModel.newPassword.accept("abcdefg1")
        
        viewModel.containsNumber.asObservable().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"abcdefg1\" should pass the number requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testMissingSpecialCharacter() {
        // Test no special character
        viewModel.newPassword.accept("abcd0123")
        viewModel.containsSpecialCharacter.asObservable().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcd0123\" should not pass the special character requirement")
            }
        }).disposed(by: disposeBag)
        
        // Ensure space doesn't count
        viewModel.newPassword.accept("abcd 1234")
        viewModel.containsSpecialCharacter.asObservable().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcd 1234\" should not pass the special character requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testContainsSpecialCharacter() {
        viewModel.newPassword.accept("abcd1234.")
        
        viewModel.containsSpecialCharacter.asObservable().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"abcd1234.\" should pass the special character requirement")
            }
        }).disposed(by: disposeBag)
    }
    
    func testPasswordMatchesUsername() {
        // Test case match
        viewModel.newPassword.accept("multprem02")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.passwordMatchesUsername.asObservable().single().subscribe(onNext: { matches in
            if !matches {
                XCTFail("Password \"multprem02\" should pass the matches username check")
            }
        }).disposed(by: disposeBag)
        
        // Test case mismatch
        viewModel.newPassword.accept("mUltpRem02")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.passwordMatchesUsername.asObservable().single().subscribe(onNext: { matches in
            if !matches {
                XCTFail("Password \"mUltpRem02\" (with capital letters) should pass the matches username check")
            }
        }).disposed(by: disposeBag)
    }
    
    func testPasswordDoesNotMatchUsername() {
        viewModel.newPassword.accept("abcdefgh")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.passwordMatchesUsername.asObservable().single().subscribe(onNext: { matches in
            if matches {
                XCTFail("Password \"abcdefgh\" should fail the matches username check")
            }
        }).disposed(by: disposeBag)
    }
    
    func testEverythingValid() {
        // Meets requirements
        viewModel.newPassword.accept("Abcdefg123")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.everythingValid.asObservable().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Password \"Abcdefg123\" should be a valid password")
            }
        }).disposed(by: disposeBag)
        
        // Does not meet requirements
        viewModel.newPassword.accept("abcdefg123")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.everythingValid.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abcdefg123\" should not be a valid password")
            }
        }).disposed(by: disposeBag)
        
        // Meets requirements but matches username
        viewModel.newPassword.accept("Multprem02")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.everythingValid.asObservable().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"Multprem02\" should not be a valid password because it matches the username")
            }
        }).disposed(by: disposeBag)
    }
    
    // This also effectively tests currentPasswordHasText() and confirmPasswordMatches()
    func testDoneButtonEnabled() {
        // Blank current password -> Disabled
        viewModel.newPassword.accept("Abcdefg123")
        viewModel.confirmPassword.accept("Abcdefg123")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.doneButtonEnabled.asObservable().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Done button should not be enabled because current password is blank")
            }
        }).disposed(by: disposeBag)
        
        // Confirm password does not match -> Disabled
        viewModel.newPassword.accept("Abcdefg123")
        viewModel.confirmPassword.accept("abcdefg123")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.doneButtonEnabled.asObservable().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Done button should not be enabled because confirm password does not match")
            }
        }).disposed(by: disposeBag)
        
        viewModel.currentPassword.accept("Password2")
        viewModel.newPassword.accept("Abcdefg123")
        viewModel.confirmPassword.accept("Abcdefg123")
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.loggedInUsername)
        viewModel.doneButtonEnabled.asObservable().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Done button should be enabled")
            }
        }).disposed(by: disposeBag)
    }
    
    func testChangePasswordCurrentPasswordIncorrect() {
        let asyncExpectation = expectation(description: "testChangePasswordCurrentPasswordIncorrect")
        
        viewModel.currentPassword.accept("invalid")
        viewModel.changePassword(
            tempPasswordWorkflow: false,
            resetPasswordWorkflow: false,
            resetPasswordUsername: nil,
            onSuccess: {
                XCTFail("Unexpected success response")
            }, onPasswordNoMatch: {
                asyncExpectation.fulfill()
            }, onError: { error in
                XCTFail("Unexpected error response")
            }
        )
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
    
    func testChangePasswordSuccess() {
        let asyncExpectation = expectation(description: "testChangePasswordSuccess")
        
        viewModel.currentPassword.accept("Password1")
        viewModel.changePassword(
            tempPasswordWorkflow: false,
            resetPasswordWorkflow: false,
            resetPasswordUsername: nil,
            onSuccess: {
                asyncExpectation.fulfill()
            }, onPasswordNoMatch: {
                XCTFail("Unexpected PasswordNoMatch response")
            }, onError: { error in
                XCTFail("Unexpected error response")
            }
        )
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "timeout")
        }
    }
}


