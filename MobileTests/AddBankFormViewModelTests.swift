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
}
