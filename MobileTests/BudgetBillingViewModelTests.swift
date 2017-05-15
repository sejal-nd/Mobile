//
//  BudgetBillingViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class BudgetBillingViewModelTests: XCTestCase {
    
    var viewModel: BudgetBillingViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        //viewModel = BudgetBillingViewModel(accountDetail: <#T##AccountDetail#>, billService: MockBillService())
    }
    
    func testSubmitButtonUnenrollingWithNoReason() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isBudgetBill": true, "CustomerInfo": [:], "BillingInfo": [:]])
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail!, billService: MockBillService())
        viewModel.currentEnrollment.value = false
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if Environment.sharedInstance.opco == .bge {
                if !enabled {
                    XCTFail("BGE - Submit button should be enabled when toggling switch off")
                }
            } else {
                if enabled {
                    XCTFail("ComEd/PECO - Submit button should be disabled when toggling switch off because no reason selected")
                }
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testSubmitButtonUnenrollingWithReason() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isBudgetBill": true, "CustomerInfo": [:], "BillingInfo": [:]])
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail!, billService: MockBillService())
        viewModel.currentEnrollment.value = false
        viewModel.selectedUnenrollmentReason.value = 1
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if Environment.sharedInstance.opco == .bge {
                if !enabled {
                    XCTFail("BGE - Submit button should be enabled when toggling switch off")
                }
            } else {
                if !enabled {
                    XCTFail("ComEd/PECO - Submit button should be enabled when toggling switch off because reason selected")
                }
            }
        }).addDisposableTo(disposeBag)
    }
    
    func testSubmitButtonEnrolling() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isBudgetBill": false, "CustomerInfo": [:], "BillingInfo": [:]])
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail!, billService: MockBillService())
        viewModel.currentEnrollment.value = true
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled because switch toggled 'On'")
            }
        }).addDisposableTo(disposeBag)
    }

}
