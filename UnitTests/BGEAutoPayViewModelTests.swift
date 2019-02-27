//
//  BGEAutoPayViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 8/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class BGEAutoPayViewModelTests: XCTestCase {
    
    var viewModel: BGEAutoPayViewModel!
    let disposeBag = DisposeBag()
    
    func testShowBottomLabel() {
        var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(), accountDetail: accountDetail)
        viewModel.showBottomLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Bottom label should show when not enrolled")
            }
        }).disposed(by: disposeBag)
        
        accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(), accountDetail: accountDetail)
        viewModel.showBottomLabel.asObservable().take(1).subscribe(onNext: { show in
            if show {
                XCTFail("Bottom label should not show when enrolled")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitButtonEnabled() {
        var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(), accountDetail: accountDetail)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.userDidReadTerms.value = true
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when unenrolled with a selected bank account")
            }
        }).disposed(by: disposeBag)
        
        accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(), accountDetail: accountDetail)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.userDidChangeSettings.value = true
        viewModel.userDidReadTerms.value = true
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when enrolled and settings changed")
            }
        }).disposed(by: disposeBag)
        
        viewModel.userDidChangeSettings.value = false
        viewModel.userDidChangeBankAccount.value = true
        viewModel.userDidReadTerms.value = true
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when enrolled and bank account changed")
            }
        }).disposed(by: disposeBag)
    }
    
}
