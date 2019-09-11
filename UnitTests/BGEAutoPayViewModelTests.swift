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
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(),
                                        walletService: MockWalletService(),
                                        accountDetail: .default)
        viewModel.showBottomLabel.asObservable().take(1).subscribe(onNext: { show in
            if !show {
                XCTFail("Bottom label should show when not enrolled")
            }
        }).disposed(by: disposeBag)
        
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(),
                                        walletService: MockWalletService(),
                                        accountDetail: .fromMockJson(forKey: .autoPay))
        viewModel.showBottomLabel.asObservable().take(1).subscribe(onNext: { show in
            if show {
                XCTFail("Bottom label should not show when enrolled")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitButtonEnabled() {
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(),
                                        walletService: MockWalletService(),
                                        accountDetail: .default)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.userDidReadTerms.value = true
        viewModel.submitButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled when unenrolled with a selected bank account")
            }
        }).disposed(by: disposeBag)
        
        viewModel = BGEAutoPayViewModel(paymentService: MockPaymentService(),
                                        walletService: MockWalletService(),
                                        accountDetail: .fromMockJson(forKey: .autoPay))
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
