//
//  AddBankFormViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AddBankFormViewModelTests: XCTestCase {
    
    var viewModel: AddBankFormViewModel!
    let disposeBag = DisposeBag()
    
    func testAccountHolderNameHasText() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.accountHolderNameHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if hasText {
                XCTFail("Account holder name should not have text when initialized")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountHolderName.value = "Test"
        viewModel.accountHolderNameHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if !hasText {
                XCTFail("Account holder name \"Test\" should have text")
            }
        }).disposed(by: disposeBag)
    }
    
    func testAccountHolderNameIsValid() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.accountHolderName.value = "a"
        viewModel.accountHolderNameIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("Account holder name \"a\" should not be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountHolderName.value = "Tes"
        viewModel.accountHolderNameIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("Account holder name \"Tes\" should be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountHolderName.value = "Teskjahsdkiquw(!!!\\)diqwudqwd\n*1237s8"
        viewModel.accountHolderNameIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("Account holder name \"Teskjahsdkiquw(!!!\\)diqwudqwd\n*1237s8\" should be valid")
            }
        }).disposed(by: disposeBag)
    }
    
    func testRoutingNumberIsValid() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.routingNumber.value = "12345678"
        viewModel.routingNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("Routing number \"12345678\" should not be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.routingNumber.value = "12345678910"
        viewModel.routingNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("Routing number \"12345678910\" should not be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.routingNumber.value = "123456789"
        viewModel.routingNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("Routing number \"123456789\" should be valid")
            }
        }).disposed(by: disposeBag)
    }
    
    func testAccountNumberNameHasText() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.accountNumberHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if hasText {
                XCTFail("Account number should not have text when initialized")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "Test"
        viewModel.accountNumberHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if !hasText {
                XCTFail("Account number \"Test\" should have text")
            }
        }).disposed(by: disposeBag)
    }
    
    func testAccountNumberIsValid() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.accountNumber.value = "123"
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("Account number \"123\" should not be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "123456789012345678"
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("Account number \"123456789012345678\" should not be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "1234" // Test exactly 4
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("Account number \"1234\" should be valid")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "12345678901234567" // Text exactly 17
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("Account number \"12345678901234567\" should be valid")
            }
        }).disposed(by: disposeBag)
    }
    
    func testConfirmAccountNumberMatches() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.accountNumber.value = "1234"
        viewModel.confirmAccountNumber.value = "123"
        viewModel.confirmAccountNumberMatches.asObservable().take(1).subscribe(onNext: { matches in
            if matches {
                XCTFail("Account numbers do not match but we said they did")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "1234"
        viewModel.confirmAccountNumber.value = "1234"
        viewModel.confirmAccountNumberMatches.asObservable().take(1).subscribe(onNext: { matches in
            if !matches {
                XCTFail("Account numbers match but we said they didn't")
            }
        }).disposed(by: disposeBag)
    }
    
    func testConfirmRoutingNumberIsEnabled() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.confirmRoutingNumberIsEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Confirm routing number should not be enabled initially")
            }
        }).disposed(by: disposeBag)
        
        viewModel.routingNumber.value = "1"
        viewModel.confirmRoutingNumberIsEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Confirm routing number should be enabled when routing number has text")
            }
        }).disposed(by: disposeBag)
    }
    
    func testConfirmAccountNumberIsEnabled() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.confirmAccountNumberIsEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Confirm account number should not be enabled initially")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "1"
        viewModel.confirmAccountNumberIsEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Confirm account number should be enabled when account number has text")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNicknameNameHasText() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        viewModel.nicknameHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if hasText {
                XCTFail("Nickname should not have text when initialized")
            }
        }).disposed(by: disposeBag)
        
        viewModel.nickname.value = "Test"
        viewModel.nicknameHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if !hasText {
                XCTFail("Nickname \"Test\" should have text")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNicknameErrorString() {
        viewModel = AddBankFormViewModel(walletService: MockWalletService())
        
        viewModel.nickname.value = "   1234 asdf"
        viewModel.nicknameErrorString.asObservable().take(1).subscribe(onNext: { errorString in
            if errorString != nil {
                XCTFail("Nickname \"   1234 asdf\" should be valid. Numbers, letters, and spaces are good")
            }
        }).disposed(by: disposeBag)
        
        viewModel.nickname.value = "Test!"
        viewModel.nicknameErrorString.asObservable().take(1).subscribe(onNext: { errorString in
            if errorString == nil {
                XCTFail("Nickname \"Test!\" should be invalid. Special characters are not allowed")
            }
        }).disposed(by: disposeBag)
        
        viewModel.nicknamesInWallet = ["TeSt"]
        viewModel.nickname.value = "test"
        viewModel.nicknameErrorString.asObservable().take(1).subscribe(onNext: { errorString in
            if errorString == nil {
                XCTFail("Duplicate nicknames should not be allowed")
            }
        }).disposed(by: disposeBag)
    }
}
