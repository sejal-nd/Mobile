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
    
}
