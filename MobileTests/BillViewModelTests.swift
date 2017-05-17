//
//  BillViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class BillViewModelTests: XCTestCase {
    
    var viewModel: BillViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        viewModel = BillViewModel(accountService: MockAccountService())
    }
    
    func testCurrentAccountDetail() {
        AccountsStore.sharedInstance.currentAccount = Account.from(["accountNumber": "1234567890"])
        viewModel.fetchAccountDetail(isRefresh: false)
        viewModel.currentAccountDetailUnwrapped.asObservable().single().subscribe(onNext: { accountDetail in
            if accountDetail.accountNumber != "1234567890" {
                XCTFail("current account detail fetch should succeed")
            }
        }).addDisposableTo(disposeBag)
    }
    
}
