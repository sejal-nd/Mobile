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
    
    func testIsUnenrolling() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isBudgetBill": true, "CustomerInfo": [:], "BillingInfo": [:]])!
        viewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: accountDetail)
        viewModel.initialEnrollmentStatus.value = BGEAutoPayViewModel.EnrollmentStatus.enrolled
        viewModel.enrollSwitchValue.value = false
        viewModel.isUnenrolling.asObservable().take(1).subscribe(onNext: { isUnenrolling in
            if !isUnenrolling {
                XCTFail("isUnenrolling should be true")
            }
        }).disposed(by: disposeBag)
    }

}
