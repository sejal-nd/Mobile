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
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.showBottomLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Bottom label should show when not enrolled")
            }
        }).disposed(by: disposeBag)
        
        accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.showBottomLabel.asObservable().take(1).subscribe(onNext: { show in
            if show {
                XCTFail("Bottom label should not show when enrolled")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitButtonEnabled() {
        var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when unenrolled with a selected bank account")
            }
        }).disposed(by: disposeBag)
        
        accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.enrollSwitchValue.value = false
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when enrolled and switch toggled off")
            }
        }).disposed(by: disposeBag)
        
        accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.userDidChangeSettings.value = true
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when enrolled and settings changed")
            }
        }).disposed(by: disposeBag)
        
        viewModel.userDidChangeSettings.value = false
        viewModel.userDidChangeBankAccount.value = true
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when enrolled and bank account changed")
            }
        }).disposed(by: disposeBag)
    }
    
    func testIsUnenrolling() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.enrollSwitchValue.value = false
        viewModel.isUnenrolling.asObservable().take(1).subscribe(onNext: { isUnenrolling in
            if !isUnenrolling {
                XCTFail("isUnenrolling should be true")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowSettingsButton() {
        var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.shouldShowSettingsButton.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Settings button should always show when enrolled")
            }
        }).disposed(by: disposeBag)
        
        accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isAutoPay": false, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.shouldShowSettingsButton.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Settings button should show when unenrolled with a selected bank account")
            }
        }).disposed(by: disposeBag)
        
        // Note: Case where settings button should be hidden when unenrolling is covered by
        // testIsUnenrolling. Entire stack view that contains the settings button is hidden
        // when unenrolling
    }
    
}
