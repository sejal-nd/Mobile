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
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: true)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.sharedInstance.opco == .bge && status != PaperlessEBillChangedStatus.Enroll {
                XCTFail("status should be .Enroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("enrollment should succeed")
        })
    }
    
    func testSingleEnrollFailure() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "0000"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "0000", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: true)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testSingleUnenrollSuccess() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: false)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.sharedInstance.opco == .bge && status != PaperlessEBillChangedStatus.Unenroll {
                XCTFail("status should be .Unenroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("unenrollment should succeed")
        })
    }
    
    func testSingleUnenrollFailure() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "0000"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "0000", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: false)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("unenrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testMultiEnrollSuccess() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!, Account.from(["accountNumber": "0987654321"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        let accountDetail2 = AccountDetail.from(["accountNumber": "0987654321", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: true)
        viewModel.switched(accountDetail: accountDetail2!, on: true)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.sharedInstance.opco == .bge && status != PaperlessEBillChangedStatus.Enroll {
                XCTFail("status should be .Enroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("multi enrollment should succeed")
        })
    }
    
    func testMultiEnrollFailure() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!, Account.from(["accountNumber": "0000"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        let accountDetail2 = AccountDetail.from(["accountNumber": "0000", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: true)
        viewModel.switched(accountDetail: accountDetail2!, on: true)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("multi enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testMultiUnenrollSuccess() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!, Account.from(["accountNumber": "0987654321"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        let accountDetail2 = AccountDetail.from(["accountNumber": "0987654321", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: false)
        viewModel.switched(accountDetail: accountDetail2!, on: false)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.sharedInstance.opco == .bge && status != PaperlessEBillChangedStatus.Unenroll {
                XCTFail("status should be .Unenroll")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("multi unenrollment should succeed")
        })
    }
    
    func testMultiUnenrollFailure() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!, Account.from(["accountNumber": "0000"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        let accountDetail2 = AccountDetail.from(["accountNumber": "0000", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: false)
        viewModel.switched(accountDetail: accountDetail2!, on: false)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("multi unenrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
    
    func testMixedEnrollSuccess() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!, Account.from(["accountNumber": "0987654321"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        let accountDetail2 = AccountDetail.from(["accountNumber": "0987654321", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: true)
        viewModel.switched(accountDetail: accountDetail2!, on: false)
        viewModel.submitChanges(onSuccess: { status in
            if Environment.sharedInstance.opco != .bge && status != PaperlessEBillChangedStatus.Mixed {
                XCTFail("status should be .Mixed")
            }
            // Pass
        }, onError: { errMessage in
            XCTFail("mixed enrollment should succeed")
        })
    }
    
    func testMixedEnrollFailure() {
        AccountsStore.sharedInstance.accounts = [Account.from(["accountNumber": "1234567890"])!, Account.from(["accountNumber": "0000"])!]
        let accountDetail = AccountDetail.from(["accountNumber": "1234567890", "isEBillEligible": true, "isEBillEnrollment": false, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        let accountDetail2 = AccountDetail.from(["accountNumber": "0000", "isEBillEligible": true, "isEBillEnrollment": true, "CustomerInfo": ["emailAddress": "test@test.com"], "BillingInfo": [:], "SERInfo": [:]])
        viewModel = PaperlessEBillViewModel(accountService: MockAccountService(), billService: MockBillService(), initialAccountDetail: accountDetail!)
        viewModel.switched(accountDetail: accountDetail!, on: true)
        viewModel.switched(accountDetail: accountDetail2!, on: false)
        viewModel.submitChanges(onSuccess: { status in
            XCTFail("mixed enrollment should fail")
        }, onError: { errMessage in
            // Pass
        })
    }
}
