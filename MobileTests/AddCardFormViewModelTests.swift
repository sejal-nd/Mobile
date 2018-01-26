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
    
    func testCardIcon(){
        //Icon does not get set until character 2 is inputted.
        viewModel.cardNumber.value = "1"
        XCTAssert(viewModel.cardIcon == nil)
        
        //American Exp. First digit must be a 3 and second digit must be a 4 or 7.
        viewModel.cardNumber.value = "344"
            XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_amex_mini"), "American Express icon is not shown for valid AmEx beginning numbers \"344\"")
        
        viewModel.cardNumber.value = "347"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_amex_mini"), "American Express icon is not shown for valid AmEx beginning numbers \"347\"")
        
        viewModel.cardNumber.value = "333"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_amex_mini")){
            XCTFail("American Express icon is shown for invalid AmEx beginning numbers \"333\"")
        }
        
        viewModel.cardNumber.value = "123"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_amex_mini")){
            XCTFail("American Express icon is shown for invalid AmEx beginning numbers \"123\"")
        }
        
        //MasterCard. First digit must be 5 and second digit must be in the range 1 through 5 inclusive. OR First digit must be 2 and second digit must be in the range 2 through 7 inclusive.
        viewModel.cardNumber.value = "51"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"51\"")
        
        viewModel.cardNumber.value = "52"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"52\"")
        
        viewModel.cardNumber.value = "53"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"53\"")
        
        viewModel.cardNumber.value = "54"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"54\"")
        
        viewModel.cardNumber.value = "55"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"55\"")
        
        viewModel.cardNumber.value = "22"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"22\"")
        
        viewModel.cardNumber.value = "23"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"23\"")
        
        viewModel.cardNumber.value = "24"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"24\"")
        
        viewModel.cardNumber.value = "25"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"25\"")
        
        viewModel.cardNumber.value = "26"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"26\"")
        
        viewModel.cardNumber.value = "27"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini"), "MasterCard icon is not shown for valid MasterCard beginning numbers \"27\"")
        
        viewModel.cardNumber.value = "123"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_mastercard_mini")){
            XCTFail("MasterCard icon is shown for invalid Mastercard beginning numbers \"123\"")
        }
        
        //Visa. First digit must be a 4.
        viewModel.cardNumber.value = "4444"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_visa_mini"), "Visa icon is not shown for valid Visa beginning numbers \"4444\"")
        
        viewModel.cardNumber.value = "40"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_visa_mini"), "Visa icon is not shown for valid Visa beginning numbers \"40\"")
        
        viewModel.cardNumber.value = "123"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_visa_mini")){
            XCTFail("Visa icon is shown for invalid Visa beginning numbers \"123\"")
        }
        
        //Discover. First 6 digits must be in one of the following ranges:
        //601100 through 601109, 601120 through 601149, 601174, 601177 through 601179, 601186 through 601199, 644000 through 659999
        
        viewModel.cardNumber.value = "344"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini")){
        XCTFail("Discover icon shown for beginning numbers \"344\" which is not >6 digits")
        }
        
        viewModel.cardNumber.value = "601100"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601100\"")
        
        viewModel.cardNumber.value = "601109"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601109\"")
        
        viewModel.cardNumber.value = "6011040456"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"6011040456\"")
        
        viewModel.cardNumber.value = "601110"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini")){
            XCTFail("Discover icon shown for beginning numbers \"601110\" which is not valid")
        }
        
        viewModel.cardNumber.value = "601120"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601120\"")
        
        viewModel.cardNumber.value = "601149"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601149\"")
        
        viewModel.cardNumber.value = "6011320456"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"6011320456\"")
        
        viewModel.cardNumber.value = "60160"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini")){
            XCTFail("Discover icon shown for beginning numbers \"60160\" which is not valid")
        }
        
        viewModel.cardNumber.value = "601177"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601177\"")
        
        viewModel.cardNumber.value = "601179"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601179\"")
        
        viewModel.cardNumber.value = "601180"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini")){
            XCTFail("Discover icon shown for beginning numbers \"601180\" which is not valid")
        }
        
        viewModel.cardNumber.value = "601186"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601186\"")
        
        viewModel.cardNumber.value = "601199878"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"601199878\"")
        
        viewModel.cardNumber.value = "601200"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini")){
            XCTFail("Discover icon shown for beginning numbers \"601180\" which is not valid")
        }
        
        viewModel.cardNumber.value = "644005"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"644005\"")
        
        viewModel.cardNumber.value = "6599999"
        XCTAssert(viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini"), "Discover icon is not shown for valid Discover beginning numbers \"6599999\"")
        
        viewModel.cardNumber.value = "660000"
        if (viewModel.cardIcon == #imageLiteral(resourceName: "ic_discover_mini")){
            XCTFail("Discover icon shown for beginning numbers \"660000\" which is not valid")
        }
        
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
    
    func testCvvIsCorrectLength() {
        viewModel.cvv.value = "1"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext:
            {isCorrectLength in
                XCTAssert(!isCorrectLength, "CVV \"1\" is not 3 or 4 digits")
        }).disposed(by: disposeBag)
        
        viewModel.cvv.value = "1234567"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext:
            {isCorrectLength in
                XCTAssert(!isCorrectLength, "CVV \"1234567\" is not 3 or 4 digits")
        }).disposed(by: disposeBag)
        
        viewModel.cvv.value = "123"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext:
            {isCorrectLength in
                XCTAssert(isCorrectLength, "CVV \"123\" is 3 or 4 digits")
        }).disposed(by: disposeBag)
        
        viewModel.cvv.value = "1234"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext:
            {isCorrectLength in
                XCTAssert(isCorrectLength, "CVV \"1234\" is 3 or 4 digits")
        }).disposed(by: disposeBag)
    }
    
    func testZipCodeIs5Digits (){
        viewModel.zipCode.value = "123"
        viewModel.zipCodeIs5Digits.asObservable().take(1).subscribe(onNext:
            {is5Digits in
                XCTAssert(!is5Digits, "Zip code \"123\" is not 5 digits")
        }).disposed(by: disposeBag)
        
        viewModel.zipCode.value = "000000"
        viewModel.zipCodeIs5Digits.asObservable().take(1).subscribe(onNext:
            {is5Digits in
                XCTAssert(!is5Digits, "Zip code \"000000\" is not 5 digits")
        }).disposed(by: disposeBag)
        
        viewModel.zipCode.value = "21230"
        viewModel.zipCodeIs5Digits.asObservable().take(1).subscribe(onNext:
            {is5Digits in
                XCTAssert(is5Digits, "Zip code \"21230\" is 5 digits")
        }).disposed(by: disposeBag)
    }
    
    func testNicknameHasText() {
        viewModel.nicknameHasText.asObservable().take(1).subscribe(onNext:
            {hasText in
                XCTAssert(!hasText, "Nickname is blank, it does not have text")
        }).disposed(by: disposeBag)
        
        
        viewModel.nickname.value = " My Card"
        viewModel.nicknameHasText.asObservable().take(1).subscribe(onNext:
            {hasText in
                XCTAssert(hasText, "Nickname \" My Card\" is not blank")
        }).disposed(by: disposeBag)
    }
    
    func testNicknameErrorString() {
        viewModel.nickname.value = "Io"
        if Environment.sharedInstance.opco == .bge {
        viewModel.nicknameErrorString.asObservable().take(1).subscribe(onNext:
            {errString in
                XCTAssert(errString == "Must be at least 3 characters", "No error string was returned")
        }).disposed(by: disposeBag)
        }
        
        viewModel.nickname.value = "My Card"
        if Environment.sharedInstance.opco == .bge {
            viewModel.nicknameErrorString.asObservable().take(1).subscribe(onNext:
                {errString in
                    if (errString == "Must be at least 3 characters"){
                        XCTFail("Error string was returned for valid nickname length")}
            }).disposed(by: disposeBag)
        }
        
        
    }
    
 
}
