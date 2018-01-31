//
//  AutoPayViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 10/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AutoPayViewModelTests: XCTestCase {
    
    var viewModel: AutoPayViewModel!
    let disposeBag = DisposeBag()
    
    func testNameOnAccountHasText() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: accountDetail)
        viewModel.nameOnAccountHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if hasText {
                XCTFail("nameOnAccount should be empty upon initialization")
            }
        }).disposed(by: disposeBag)
        
        viewModel.nameOnAccount.value = "Test"
        viewModel.nameOnAccountHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if !hasText {
                XCTFail("nameOnAccount \"Test\" should return hasText = true")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNameOnAccountIsValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: accountDetail)
        viewModel.nameOnAccountIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("nameOnAccount should be valid upon initialization")
            }
        }).disposed(by: disposeBag)
        
        viewModel.nameOnAccount.value = "Test Test"
        viewModel.nameOnAccountIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("nameOnAccount \"Test Test\" should return isValid = true")
            }
        }).disposed(by: disposeBag)
        
        viewModel.nameOnAccount.value = "Test!Test"
        viewModel.nameOnAccountIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("nameOnAccount \"Test!Test\" should return isValid = false because of the special character")
            }
        }).disposed(by: disposeBag)
    }

    func testRoutingNumberIsValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: accountDetail)
        viewModel.routingNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("routingNumber should be invalid upon initialization")
            }
        }).disposed(by: disposeBag)
        
        viewModel.routingNumber.value = "123456789"
        viewModel.routingNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("routingNumber 123456789 should be valid")
            }
        }).disposed(by: disposeBag)
    }
    
    func testAccountNumberHasText() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: accountDetail)
        viewModel.accountNumberHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if hasText {
                XCTFail("accountNumberHasText should be empty upon initialization")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "1234"
        viewModel.accountNumberHasText.asObservable().take(1).subscribe(onNext: { hasText in
            if !hasText {
                XCTFail("accountNumber 1234 should return hasText = true")
            }
        }).disposed(by: disposeBag)
    }
    
    func testAccountNumberIsValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: accountDetail)
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("accountNumber should be invalid upon initialization")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "123"
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("accountNumber 123 should be invalid (less than 4 characters)")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "111111111111111111"
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if isValid {
                XCTFail("accountNumber 111111111111111111 should be invalid (greater than 17 characters)")
            }
        }).disposed(by: disposeBag)
        
        viewModel.accountNumber.value = "1234567"
        viewModel.accountNumberIsValid.asObservable().take(1).subscribe(onNext: { isValid in
            if !isValid {
                XCTFail("accountNumber 1234567 should be valid")
            }
        }).disposed(by: disposeBag)
    }
    
    func testConfirmAccountNumberMatches() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: accountDetail)
        
        viewModel.accountNumber.value = "Match"
        viewModel.confirmAccountNumber.value = "NoMatch"
        viewModel.confirmAccountNumberMatches.asObservable().take(1).subscribe(onNext: { matches in
            if matches {
                XCTFail("accountNumbers \"Match\" and \"NoMatch\" should not match")
            }
        }).disposed(by: disposeBag)
        
        viewModel.confirmAccountNumber.value = "Match"
        viewModel.confirmAccountNumberMatches.asObservable().take(1).subscribe(onNext: { matches in
            if !matches {
                XCTFail("accountNumbers tested should return matches = true")
            }
        }).disposed(by: disposeBag)
    }
}
