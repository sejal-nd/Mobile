//
//  AddCreditCardFormViewModelTests.swift
//  Mobile
//
//  Created by Joe Ezeh on 1/17/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AddCardFormViewModelTests: XCTestCase {
    
    var viewModel: AddCardFormViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        viewModel = AddCardFormViewModel(walletService: MockWalletService())
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNameOnCardHasText() {
        viewModel.nameOnCardHasText.asObservable().take(1).subscribe(onNext:
            {hasText in
                    XCTAssert(!hasText, "Name on Card should not have text when initialized")
        }).disposed(by: disposeBag)
        
        viewModel.nameOnCard.value = "Test Johnson"
        viewModel.nameOnCardHasText.asObservable().take(1).subscribe(onNext:
            {hasText in
                    XCTAssert(hasText, "Name on Card field should have text \"Test Johnson\"")
        }).disposed(by: disposeBag)
    }
    
    func testCardNumberHasText() {
        viewModel.cardNumberHasText.asObservable().take(1).subscribe(onNext:
            {hasText in
                    XCTAssert(!hasText, "Card number should not have text when initialized")
        }).disposed(by: disposeBag)
        
        viewModel.cardNumber.value = "4444554544069948"
        viewModel.cardNumberHasText.asObservable().take(1).subscribe(onNext:
            {hasText in
                    XCTAssert(hasText, "Card number should have text \"4444554544069948\"")
        }).disposed(by: disposeBag)
    }
    
    func testCardNumberIsValid() {
        viewModel.cardNumber.value = "123"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Card number \"123\" should not be considered valid")
        }).disposed(by: disposeBag)
        
        //Per business reqs, should reject any number starting with 0,1,7,8,9
        viewModel.cardNumber.value = "0000000000000000"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Card number \"0000000000000000\" should not be considered valid")
        }).disposed(by: disposeBag)
        
        viewModel.cardNumber.value = "1234567890005555"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Card number \"1234567890005555\" should not be considered valid")
        }).disposed(by: disposeBag)
        
        viewModel.cardNumber.value = "7777777777"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Card number \"7777777777\" should not be considered valid")
        }).disposed(by: disposeBag)
        
        viewModel.cardNumber.value = "8888888877778888"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Card number \"8888888877778888\" should not be considered valid")
        }).disposed(by: disposeBag)
        
        viewModel.cardNumber.value = "9999877799999999"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Card number \"9999877799999999\" should not be considered valid")
        }).disposed(by: disposeBag)
        
        //Valid card number
        viewModel.cardNumber.value = "4111111111111111"
        viewModel.cardNumberIsValid.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(isValid, "Card number \"4111111111111111\" should be valid")
        }).disposed(by: disposeBag)
    }

    func testExpMonthIs2Digits() {
        viewModel.expMonth.value = "1"
        viewModel.expMonthIs2Digits.asObservable().take(1).subscribe(onNext:
            {is2Digits in
                    XCTAssert(!is2Digits, "Exp Month \"1\" is less than 2 digits")
        }).disposed(by: disposeBag)
        
        viewModel.expMonth.value = "000"
        viewModel.expMonthIs2Digits.asObservable().take(1).subscribe(onNext:
            {is2Digits in
                    XCTAssert(!is2Digits, "Exp Month \"000\" is greater than 2 digits")
        }).disposed(by: disposeBag)
        
        viewModel.expMonth.value = "10"
        viewModel.expMonthIs2Digits.asObservable().take(1).subscribe(onNext:
            {is2Digits in
                    XCTAssert(is2Digits, "Exp Month \"10\" is 2 digits")
        }).disposed(by: disposeBag)
    }
    
    func testExpMonthIsValidMonth() {
        viewModel.expMonth.value = "13"
        viewModel.expMonthIsValidMonth.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Exp Month \"13\" is not a valid month")
        }).disposed(by: disposeBag)
        
        viewModel.expMonth.value = "00"
        viewModel.expMonthIsValidMonth.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Exp Month \"00\" is not a valid month")
        }).disposed(by: disposeBag)
        
        viewModel.expMonth.value = "6"
        viewModel.expMonthIsValidMonth.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(!isValid, "Exp Month \"6\" is not a valid month, should be \"06\"")
        }).disposed(by: disposeBag)
        
        viewModel.expMonth.value = "06"
        viewModel.expMonthIsValidMonth.asObservable().take(1).subscribe(onNext:
            {isValid in
                    XCTAssert(isValid, "Exp Month \"06\" is a valid month")
        }).disposed(by: disposeBag)
    }
    
    func testExpYearIs4Digits() {
        viewModel.expYear.value = "1"
         viewModel.expYearIs4Digits.asObservable().take(1).subscribe(onNext:
            {is4Digits in
                XCTAssert(!is4Digits, "Exp Year \"1\" is not 4 digits long")
        }).disposed(by: disposeBag)
        
        viewModel.expYear.value = "2020"
        viewModel.expYearIs4Digits.asObservable().take(1).subscribe(onNext:
            {is4Digits in
                XCTAssert(is4Digits, "Exp Year \"2020\" is 4 digits long")
        }).disposed(by: disposeBag)
    }
    
    func testExpYearIsNotInPast() {
        viewModel.expYear.value = "1000"
        viewModel.expYearIsNotInPast.asObservable().take(1).subscribe(onNext:
            {isInPast in
                XCTAssert(!isInPast, "Exp Year \"1000\" is in the past")
        }).disposed(by: disposeBag)
        
        viewModel.expYear.value = "2050"
        viewModel.expYearIsNotInPast.asObservable().take(1).subscribe(onNext:
            {isInPast in
                XCTAssert(isInPast, "Exp Year \"2050\" is not in the past")
        }).disposed(by: disposeBag)
    }
}
