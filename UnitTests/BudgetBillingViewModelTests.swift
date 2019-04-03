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
        super.setUp()
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
    }
    
    func testSubmitButtonUnenrollingWithNoReason() {
        viewModel = BudgetBillingViewModel(accountDetail: .fromMockJson(forKey: .budgetBill), billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.currentEnrollment.value = false
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if Environment.shared.opco == .bge {
                if !enabled {
                    XCTFail("BGE - Submit button should be enabled when toggling switch off")
                }
            } else {
                if enabled {
                    XCTFail("ComEd/PECO - Submit button should be disabled when toggling switch off because no reason selected")
                }
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitButtonUnenrollingWithReason() {
        viewModel = BudgetBillingViewModel(accountDetail: .fromMockJson(forKey: .budgetBill), billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.currentEnrollment.value = false
        viewModel.selectedUnenrollmentReason.value = 1
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if Environment.shared.opco == .bge {
                if !enabled {
                    XCTFail("BGE - Submit button should be enabled when toggling switch off")
                }
            } else {
                if !enabled {
                    XCTFail("ComEd/PECO - Submit button should be enabled when toggling switch off because reason selected")
                }
            }
        }).disposed(by: disposeBag)
    }
    
    func testSubmitButtonEnrolling() {
        viewModel = BudgetBillingViewModel(accountDetail: .default, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.currentEnrollment.value = true
        viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
            if !enabled {
                XCTFail("Submit button should be enabled because switch toggled 'On'")
            }
        }).disposed(by: disposeBag)
    }
    
    func testGetBudgetBillingInfoSuccess() {
        viewModel = BudgetBillingViewModel(accountDetail: .default, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.getBudgetBillingInfo(onSuccess: { info in
            // Pass
        }, onError: { errMessage in
            XCTFail("Fetching budget billing info should succeed")
        })
    }
    
    func testGetBudgetBillingInfoFailure() {
        let accountDetail = AccountDetail.from(["accountNumber": "0000",
                                                "CustomerInfo": [:],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail!, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.getBudgetBillingInfo(onSuccess: { info in
            XCTFail("Fetching budget billing info should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testEnrollSuccess() {
        viewModel = BudgetBillingViewModel(accountDetail: .default, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.enroll(onSuccess: { 
            // Pass
        }, onError: { errMessage in
            XCTFail("Enrollment should succeed")
        })
    }
    
    func testEnrollFailure() {
        let accountDetail = AccountDetail.from(["accountNumber": "0000",
                                                "CustomerInfo": [:],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail!, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.enroll(onSuccess: {
            XCTFail("Enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testUnenrollSuccess() {
        viewModel = BudgetBillingViewModel(accountDetail: .default, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.selectedUnenrollmentReason.value = 1
        viewModel.unenroll(onSuccess: {
            // Pass
        }, onError: { errMessage in
            XCTFail("Enrollment should succeed")
        })
    }
    
    func testUnenrollFailure() {
        let accountDetail = AccountDetail.from(["accountNumber": "0000",
                                                "CustomerInfo": [:],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])
        viewModel = BudgetBillingViewModel(accountDetail: accountDetail!, billService: MockBillService(), alertsService: MockAlertsService())
        viewModel.unenroll(onSuccess: {
            XCTFail("Enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }

}
