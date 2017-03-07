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
    var viewModel: ChangePasswordViewModel?
    
    override func setUp() {
        UserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        
        viewModel = ChangePasswordViewModel(userDefaults: userDefaults!, authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
    }

    func testTooFewCharacterCount() {
        viewModel!.newPassword.value = "abc"
        
        viewModel!.characterCountValid().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abc\" should result in an invalid character count")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testTooManyCharacterCount() {
        viewModel!.newPassword.value = "abcdefghijklmnopqrstuvwxzy"
        
        viewModel!.characterCountValid().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abcdefghijklmnopqrstuvwxzy\" should result in an invalid character count")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testWhitespaceCharacterCount() {
        viewModel!.newPassword.value = "abc       d"
        
        viewModel!.characterCountValid().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abc       d\" (with whitespace) should result in an invalid character count")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testValidCharacterCount() {
        viewModel!.newPassword.value = "abcdefgh"
        
        viewModel!.characterCountValid().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Password \"abcdefgh\" should result in a valid character count")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testMissingUppercaseLetter() {
        viewModel!.newPassword.value = "abcdefgh"
        
        viewModel!.containsUppercaseLetter().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcdefgh\" should not pass the uppercase letter requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testContainsUppercaseLetter() {
        viewModel!.newPassword.value = "Abcdefgh"
        
        viewModel!.containsUppercaseLetter().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"Abcdefgh\" should pass the uppercase letter requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testMissingLowercaseLetter() {
        viewModel!.newPassword.value = "ABCDEFGH"
        
        viewModel!.containsLowercaseLetter().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"ABCDEFGH\" should not pass the lowercase letter requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testContainsLowercaseLetter() {
        viewModel!.newPassword.value = "aBCDEFGH"
        
        viewModel!.containsLowercaseLetter().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"aBCDEFGH\" should pass the lowercase letter requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testMissingNumber() {
        viewModel!.newPassword.value = "abcdefgh"
        
        viewModel!.containsNumber().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcdefgh\" should not pass the number requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testContainsNumber() {
        viewModel!.newPassword.value = "abcdefg1"
        
        viewModel!.containsNumber().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"abcdefg1\" should pass the number requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testMissingSpecialCharacter() {
        // Test no special character
        viewModel!.newPassword.value = "abcd0123"
        viewModel!.containsSpecialCharacter().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcd0123\" should not pass the special character requirement")
            }
        }).addDisposableTo(disposeBag)
        
        // Ensure space doesn't count
        viewModel!.newPassword.value = "abcd 1234"
        viewModel!.containsSpecialCharacter().single().subscribe(onNext: { contains in
            if contains {
                XCTFail("Password \"abcd 1234\" should not pass the special character requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testContainsSpecialCharacter() {
        viewModel!.newPassword.value = "abcd1234."
        
        viewModel!.containsSpecialCharacter().single().subscribe(onNext: { contains in
            if !contains {
                XCTFail("Password \"abcd1234.\" should pass the special character requirement")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testPasswordMatchesUsername() {
        // Test case match
        viewModel!.newPassword.value = "multprem02"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.passwordMatchesUsername().single().subscribe(onNext: { matches in
            if !matches {
                XCTFail("Password \"multprem02\" should pass the matches username check")
            }
        }).addDisposableTo(disposeBag)
        
        // Test case mismatch
        viewModel!.newPassword.value = "mUltpRem02"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.passwordMatchesUsername().single().subscribe(onNext: { matches in
            if !matches {
                XCTFail("Password \"mUltpRem02\" (with capital letters) should pass the matches username check")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testPasswordDoesNotMatchUsername() {
        viewModel!.newPassword.value = "abcdefgh"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.passwordMatchesUsername().single().subscribe(onNext: { matches in
            if matches {
                XCTFail("Password \"abcdefgh\" should fail the matches username check")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testEverythingValid() {
        // Meets requirements
        viewModel!.newPassword.value = "Abcdefg123"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.everythingValid().single().subscribe(onNext: { valid in
            if !valid {
                XCTFail("Password \"Abcdefg123\" should be a valid password")
            }
        }).addDisposableTo(disposeBag)
        
        // Does not meet requirements
        viewModel!.newPassword.value = "abcdefg123"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.everythingValid().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"abcdefg123\" should not be a valid password")
            }
        }).addDisposableTo(disposeBag)
        
        // Meets requirements but matches username
        viewModel!.newPassword.value = "Multprem02"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.everythingValid().single().subscribe(onNext: { valid in
            if valid {
                XCTFail("Password \"Multprem02\" should not be a valid password because it matches the username")
            }
        }).addDisposableTo(disposeBag)
    }
    
    // This also effectively tests currentPasswordHasText() and confirmPasswordMatches()
    func testDoneButtonEnabled() {
        // Blank current password -> Disabled
        viewModel!.newPassword.value = "Abcdefg123"
        viewModel!.confirmPassword.value = "Abcdefg123"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.doneButtonEnabled().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Done button should not be enabled because current password is blank")
            }
        }).addDisposableTo(disposeBag)
        
        // Confirm password does not match -> Disabled
        viewModel!.newPassword.value = "Abcdefg123"
        viewModel!.confirmPassword.value = "abcdefg123"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.doneButtonEnabled().single().subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Done button should not be enabled because confirm password does not match")
            }
        }).addDisposableTo(disposeBag)
        
        viewModel!.currentPassword.value = "Password2"
        viewModel!.newPassword.value = "Abcdefg123"
        viewModel!.confirmPassword.value = "Abcdefg123"
        userDefaults!.setValue("multprem02", forKey: UserDefaultKeys.LoggedInUsername)
        viewModel!.doneButtonEnabled().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Done button should be enabled")
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testChangePasswordCurrentPasswordIncorrect() {
        // Use mock AuthenticationService
    }
}


