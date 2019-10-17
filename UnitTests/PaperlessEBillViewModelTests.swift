//
//  PaperlessEBillViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class PaperlessEBillViewModelTests: XCTestCase {
    
    var viewModel: PaperlessEBillViewModel!
    let disposeBag = DisposeBag()
    
    func testSingleEnrollSuccess() {
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.fromMockJson(forKey: .eBillEligible)
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: true)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.shared.opco == .bge && status != PaperlessEBillChangedStatus.enroll {
                XCTFail("status should be .Enroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("enrollment should succeed")
        })
    }
    
    func testSingleEnrollFailure() {
        MockUser.current = MockUser(globalKeys: .accountZeros)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "0000",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": false,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: true)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testSingleUnenrollSuccess() {
        MockUser.current = MockUser(globalKeys: .eBill)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.fromMockJson(forKey: .eBill)
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: false)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.shared.opco == .bge && status != PaperlessEBillChangedStatus.unenroll {
                XCTFail("status should be .Unenroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("unenrollment should succeed")
        })
    }
    
    func testSingleUnenrollFailure() {
        MockUser.current = MockUser(globalKeys: .accountZeros)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "0000",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": true,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: false)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("unenrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testMultiEnrollSuccess() {
        MockUser.current = MockUser(globalKeys: .default, .default)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": false,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        let accountDetail2 = AccountDetail.from(["accountNumber": "0987654321",
                                                 "isEBillEligible": true,
                                                 "isEBillEnrollment": false,
                                                 "CustomerInfo": ["emailAddress": "test@test.com"],
                                                 "BillingInfo": ["minimumPaymentAmount": 5,
                                                                 "maximumPaymentAmount": 5000,
                                                                 "maximumPaymentAmountACH": 100000,
                                                                 "convenienceFee": 5.95],
                                                 "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: true)
        viewModel.switched(accountDetail: accountDetail2, on: true)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.shared.opco == .bge && status != PaperlessEBillChangedStatus.enroll {
                XCTFail("status should be .Enroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("multi enrollment should succeed")
        })
    }
    
    func testMultiEnrollFailure() {
        MockUser.current = MockUser(globalKeys: .default, .accountZeros)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": false,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        let accountDetail2 = AccountDetail.from(["accountNumber": "0000",
                                                 "isEBillEligible": true,
                                                 "isEBillEnrollment": false,
                                                 "CustomerInfo": ["emailAddress": "test@test.com"],
                                                 "BillingInfo": ["minimumPaymentAmount": 5,
                                                                 "maximumPaymentAmount": 5000,
                                                                 "maximumPaymentAmountACH": 100000,
                                                                 "convenienceFee": 5.95],
                                                 "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: true)
        viewModel.switched(accountDetail: accountDetail2, on: true)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("multi enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testMultiUnenrollSuccess() {
        MockUser.current = MockUser(globalKeys: .default, .default)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": true,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        let accountDetail2 = AccountDetail.from(["accountNumber": "0987654321",
                                                 "isEBillEligible": true,
                                                 "isEBillEnrollment": true,
                                                 "CustomerInfo": ["emailAddress": "test@test.com"],
                                                 "BillingInfo": ["minimumPaymentAmount": 5,
                                                                 "maximumPaymentAmount": 5000,
                                                                 "maximumPaymentAmountACH": 100000,
                                                                 "convenienceFee": 5.95],
                                                 "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: false)
        viewModel.switched(accountDetail: accountDetail2, on: false)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.shared.opco == .bge && status != PaperlessEBillChangedStatus.unenroll {
                XCTFail("status should be .Unenroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("multi unenrollment should succeed")
        })
    }
    
    func testMultiUnenrollFailure() {
        MockUser.current = MockUser(globalKeys: .default, .default)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": true,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        let accountDetail2 = AccountDetail.from(["accountNumber": "0000",
                                                 "isEBillEligible": true,
                                                 "isEBillEnrollment": true,
                                                 "CustomerInfo": ["emailAddress": "test@test.com"],
                                                 "BillingInfo": ["minimumPaymentAmount": 5,
                                                                 "maximumPaymentAmount": 5000,
                                                                 "maximumPaymentAmountACH": 100000,
                                                                 "convenienceFee": 5.95],
                                                 "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: false)
        viewModel.switched(accountDetail: accountDetail2, on: false)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("multi unenrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testMixedEnrollSuccess() {
        MockUser.current = MockUser(globalKeys: .default, .default)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": false,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        let accountDetail2 = AccountDetail.from(["accountNumber": "0987654321",
                                                 "isEBillEligible": true,
                                                 "isEBillEnrollment": true,
                                                 "CustomerInfo": ["emailAddress": "test@test.com"],
                                                 "BillingInfo": ["minimumPaymentAmount": 5,
                                                                 "maximumPaymentAmount": 5000,
                                                                 "maximumPaymentAmountACH": 100000,
                                                                 "convenienceFee": 5.95],
                                                 "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: true)
        viewModel.switched(accountDetail: accountDetail2, on: false)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.shared.opco != .bge && status != PaperlessEBillChangedStatus.mixed {
                XCTFail("status should be .Mixed")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("mixed enrollment should succeed")
        })
    }
    
    func testMixedEnrollFailure() {
        MockUser.current = MockUser(globalKeys: .default, .default)
        MockAccountService.loadAccountsSync()
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890",
                                                "isEBillEligible": true,
                                                "isEBillEnrollment": false,
                                                "CustomerInfo": ["emailAddress": "test@test.com"],
                                                "BillingInfo": ["minimumPaymentAmount": 5,
                                                                "maximumPaymentAmount": 5000,
                                                                "maximumPaymentAmountACH": 100000,
                                                                "convenienceFee": 5.95],
                                                "SERInfo": [:]])!
        let accountDetail2 = AccountDetail.from(["accountNumber": "0000",
                                                 "isEBillEligible": true,
                                                 "isEBillEnrollment": true,
                                                 "CustomerInfo": ["emailAddress": "test@test.com"],
                                                 "BillingInfo": ["minimumPaymentAmount": 5,
                                                                 "maximumPaymentAmount": 5000,
                                                                 "maximumPaymentAmountACH": 100000,
                                                                 "convenienceFee": 5.95],
                                                 "SERInfo": [:]])!
        
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail)
        viewModel.switched(accountDetail: accountDetail, on: true)
        viewModel.switched(accountDetail: accountDetail2, on: false)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("mixed enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
}
