//
//  PaymentViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 1/15/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift


class PaymentViewModelTests: XCTestCase {

    var viewModel: PaymentViewModel!
    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testFetchDataHappyPath() {
        let accountDetail = AccountDetail(isResidential: true)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        AccountsStore.shared.accounts = [Account.from(["accountNumber": "1234", "address": "573 Elm Street"])!]
        AccountsStore.shared.currentIndex = 0
        let expect = expectation(description: "async")
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertFalse(self.viewModel.isFetching.value)
            XCTAssertNotNil(self.viewModel.walletItems.value, "walletItems should have been set")
            XCTAssert(self.viewModel.walletItems.value!.count == 2, "2 wallet items should have been returned")
            XCTAssertNotNil(self.viewModel.oneTouchPayItem, "oneTouchPayItem should have been set because one of the wallet items was default")
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should have been set to a default")
            XCTAssert(self.viewModel.selectedWalletItem.value!.nickName == "Test Nickname 2", "selectedWalletItem should have been defaulted to OTP item")
            expect.fulfill()
        }, onError: {
            XCTFail("unexpected error response")
        })

        XCTAssert(viewModel.isFetching.value, "isFetching should be true as soon as fetchData is called")

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testFetchDataHappyPathNoOTPItem() {
        let accountDetail = AccountDetail(isResidential: true)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        AccountsStore.shared.accounts = [Account.from(["accountNumber": "13"])!] // Will trigger no OTP item from fetchWalletItems mock
        AccountsStore.shared.currentIndex = 0
        let expect = expectation(description: "async")
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertFalse(self.viewModel.isFetching.value)
            XCTAssertNotNil(self.viewModel.walletItems.value, "walletItems should have been set")
            XCTAssert(self.viewModel.walletItems.value!.count == 2, "2 wallet items should have been returned")
            XCTAssertNil(self.viewModel.oneTouchPayItem, "oneTouchPayItem should be nil because no wallet items are default")
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should have been set to a default")
            XCTAssert(self.viewModel.selectedWalletItem.value!.nickName == "Test Nickname", "selectedWalletItem should have been defaulted to first wallet item ")
            expect.fulfill()
        }, onError: {
            XCTFail("unexpected error response")
        })

        XCTAssert(viewModel.isFetching.value, "isFetching should be true as soon as fetchData is called")

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testFetchDataModifyPayment() {
        let accountDetail = AccountDetail(isResidential: true)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.paymentId.value = "1"
        let expect = expectation(description: "async")
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssert(self.viewModel.paymentAmount.value == 100.00, "Expected \"100.00\", got \"\(self.viewModel.paymentAmount.value)\")")
            XCTAssert(self.viewModel.paymentDate.value == Date(timeIntervalSince1970: 13), "paymentDate should have been updated from the paymentDetail")
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should have been set to the matching walletId from the paymentDetail")
            expect.fulfill()
        }, onError: {
            XCTFail("unexpected error response")
        })

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testFetchDataCashOnly() {
        let accountDetail = AccountDetail(isCashOnly: true, isResidential: true)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        AccountsStore.shared.accounts = [Account.from(["accountNumber": "1234"])!]
        AccountsStore.shared.currentIndex = 0
        let expect1 = expectation(description: "async")
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should not be nil because OTP item is credit card")
            XCTAssert(self.viewModel.selectedWalletItem.value!.nickName == "Test Nickname 2")
            expect1.fulfill()
        }, onError: {
            XCTFail("unexpected error response")
        })

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }

        AccountsStore.shared.accounts = [Account.from(["accountNumber": "13"])!] // Will trigger no OTP item from fetchWalletItems mock
        AccountsStore.shared.currentIndex = 0

        viewModel.selectedWalletItem.value = nil // Reset
        let expect2 = expectation(description: "async")
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should not be nil because wallet items include a credit card")
            XCTAssert(self.viewModel.selectedWalletItem.value!.nickName == "Test Nickname", "got \(self.viewModel.selectedWalletItem.value!.nickName ?? "nil")")
            expect2.fulfill()
        }, onError: {
            XCTFail("unexpected error response")
        })

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testSchedulePaymentExistingWalletItem() {
        let accountDetail = AccountDetail()
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        AccountsStore.shared.customerIdentifier = "123"
        viewModel.selectedWalletItem.value = WalletItem()
        let expect = expectation(description: "async")
        viewModel.schedulePayment(onDuplicate: { (title, message) in
            XCTFail("unexpected onDuplicate response")
        }, onSuccess: {
            expect.fulfill()
        }, onError: { err in
            XCTFail("unexpected onError response")
        })

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testCancelPayment() {
        let accountDetail = AccountDetail()
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        AccountsStore.shared.customerIdentifier = "123"
        viewModel.paymentId.value = "123"
        viewModel.paymentDetail.value = PaymentDetail(walletItemId: "123", paymentAmount: 123, paymentDate: .now)
        let expect = expectation(description: "async")
        viewModel.cancelPayment(onSuccess: {
            expect.fulfill()
        }, onError: { err in
            XCTFail("unexpected onError response")
        })

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testModifyPayment() {
        let accountDetail = AccountDetail()
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        AccountsStore.shared.customerIdentifier = "123"
        viewModel.paymentId.value = "123"
        viewModel.paymentDetail.value = PaymentDetail(walletItemId: "123", paymentAmount: 123, paymentDate: .now)
        viewModel.selectedWalletItem.value = WalletItem()
        let expect = expectation(description: "async")
        viewModel.modifyPayment(onSuccess: {
            expect.fulfill()
        }, onError: { err in
            XCTFail("unexpected onError response")
        })

        waitForExpectations(timeout: 3) { err in
            XCTAssertNil(err, "timeout")
        }
    }

    func testBankWorkflow() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            XCTAssertFalse(bankWorkflow, "bankWorkflow should be false initially")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            XCTAssert(bankWorkflow, "bankWorkflow should be true when selectedWalletItem is a bank account")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            XCTAssertFalse(bankWorkflow, "bankWorkflow should be false when selectedWalletItem is a card")
        }).disposed(by: disposeBag)
    }

    func testCardWorkflow() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssertFalse(cardWorkflow, "cardWorkflow should be false initially")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssert(cardWorkflow, "cardWorkflow should be true when selectedWalletItem is a card")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssertFalse(cardWorkflow, "cardWorkflow should be false when selectedWalletItem is a bank account")
        }).disposed(by: disposeBag)
    }


    func testPaymentFieldsValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.paymentAmount.value = 100
        viewModel.paymentFieldsValid.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "paymentFieldsValid should be valid for this test case")
        }).disposed(by: disposeBag)
    }

    func testMakePaymentNextButtonEnabled() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        // Initial state
        viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            XCTAssertFalse(enabled, "Next button should not be enabled initially")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            XCTAssert(enabled, "Next button should be enabled for this test case")
        }).disposed(by: disposeBag)
    }

    func testShouldShowNextButton() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.shouldShowNextButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "Next button should show by default")
        }).disposed(by: disposeBag)

        viewModel.paymentId.value = "123"
        viewModel.allowEdits.value = false
        viewModel.shouldShowNextButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "Next button should not show when allowEdits is false")
        }).disposed(by: disposeBag)

        viewModel.allowEdits.value = true
        viewModel.shouldShowNextButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "Next button should show when allowEdits is true")
        }).disposed(by: disposeBag)
    }

    func testShouldShowPaymentAccountView() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "Payment method view should not be shown by default")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "Payment method view should be shown after a wallet item is selected")
        }).disposed(by: disposeBag)
    }

    func testHasWalletItems() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isCashOnly": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        // Cash only user test - bank accounts should be ignored
        viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank)]
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssertFalse(hasWalletItems, "hasWalletItems should be false for a cash only user with only include bank accounts")
        }).disposed(by: disposeBag)
        viewModel.walletItems.value!.append(WalletItem(bankOrCard: .card))
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssert(hasWalletItems, "hasWalletItems should be true for a cash only user with a credit card")
        }).disposed(by: disposeBag)

        // Normal test case
        viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel.walletItems.value = []
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssertFalse(hasWalletItems, "hasWalletItems should be false for a normal scenario with no wallet items")
        }).disposed(by: disposeBag)
        viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .card)]
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssert(hasWalletItems, "hasWalletItems should be true for a normal scenario with wallet items")
        }).disposed(by: disposeBag)
    }

    func testShouldShowPaymentAmountTextField() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        // Allow edits false
        viewModel.allowEdits.value = false
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(!shouldShow, "paymentAmountTextField should not show when allowEdits is false")
        }).disposed(by: disposeBag)

        // Has Wallet Items
        viewModel.allowEdits.value = true
        viewModel.walletItems.value = [WalletItem(bankOrCard: .bank)]
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "paymentAmountTextField should show when user has wallet items")
        }).disposed(by: disposeBag)
    }

    /* TODO!! Uncomment these tests during epay R2 when the values will come from accountDetail.BillingInfo again

    // Test paymentAmountErrorMessage for BGE bank accounts when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageBGEBankFromAccountDetail() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "minimumPaymentAmountACH": 0.001, "maximumPaymentAmountACH": 1_500_000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.inlineBank.value = true
            viewModel.paymentAmount.value = 0.0009
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 1600000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 0.001
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 1500000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }

    // Test paymentAmountErrorMessage for ComEd/PECO bank accounts when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageComEdPECOBankFromAccountDetail() {
        if Environment.shared.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 20_000, "minimumPaymentAmountACH": 3, "maximumPaymentAmountACH": 10_000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.inlineBank.value = true
            viewModel.paymentAmount.value = 2
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 11000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 3
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 10000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)

            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = 900
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }

    // Test paymentAmountErrorMessage for BGE credit cards when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageBGECardFromAccountDetail() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "minimumPaymentAmount": 0.001, "maximumPaymentAmount": 30000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.inlineCard.value = true
            viewModel.paymentAmount.value = 0.0009
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 31000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 0.001
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 30000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }

    // Test paymentAmountErrorMessage for ComEd/PECO credit cards when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageComEdPECOCardFromAccountDetail() {
        if Environment.shared.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 20_000, "minimumPaymentAmount": 3, "maximumPaymentAmount": 6000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.inlineCard.value = true
            viewModel.paymentAmount.value = 2
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 7000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 3
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 6000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)

            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = 900
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }
    */

    // Test paymentAmountErrorMessage for BGE bank accounts when using the hardcoded min/max values
    func testPaymentAmountErrorMessageBGEBankHardcoded() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.paymentAmount.value = 0
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            // Commercial max
            viewModel.paymentAmount.value = 1000000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 0.01
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            // Commercial max
            viewModel.paymentAmount.value = 999999.99
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)

            // Residential max
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel.paymentAmount.value = 100000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            // Residential max
            viewModel.paymentAmount.value = 99999.99
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }

    // Test paymentAmountErrorMessage for ComEd/PECO bank accounts when using the hardcoded min/max values
    func testPaymentAmountErrorMessageComEdPECOBankHardcoded() {
        if Environment.shared.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 100000], "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.paymentAmount.value = 4
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 200000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 5
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 100000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)

            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = 900
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }

    // Test paymentAmountErrorMessage for BGE credit cards when using the hardcoded min/max values
    func testPaymentAmountErrorMessageBGECardHardcoded() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmount.value = 0.009
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            // Commercial max
            viewModel.paymentAmount.value = 26000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 0.01
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            // Commercial max
            viewModel.paymentAmount.value = 25000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)

            // Residential max
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel.paymentAmount.value = 700
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            // Residential max
            viewModel.paymentAmount.value = 600
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }

    // Test paymentAmountErrorMessage for ComEd/PECO credit cards when using the hardcoded min/max values
    func testPaymentAmountErrorMessageComEdPECOCardHardcoded() {
        if Environment.shared.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 20_000], "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmount.value = 4
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 6000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 5
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)

            viewModel.paymentAmount.value = 5000
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)

            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = 900
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }

    func testPaymentAmountFeeLabelTextBank() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText ?? "nil")\"")
            }).disposed(by: disposeBag)
        } else { // ComEd/PECO
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText ?? "nil")\"")
            }).disposed(by: disposeBag)
        }
    }

    func testPaymentAmountFeeLabelTextCard() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("A convenience fee will be applied to this payment. Residential accounts: $2.00. Business accounts: 5%.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText ?? "nil")\"")
            }).disposed(by: disposeBag)
        } else {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("A $2.00 convenience fee will be applied by Paymentus, our payment partner.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText ?? "nil")\"")
            }).disposed(by: disposeBag)
        }
    }

    func testPaymentAmountFeeFooterLabelTextBank() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText)\"")
            }).disposed(by: disposeBag)
        } else { // ComEd/PECO
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText)\"")
            }).disposed(by: disposeBag)
        }
    }

    func testPaymentAmountFeeFooterLabelTextCardResidential() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("Your payment includes a $2.00 convenience fee.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText)\"")
            }).disposed(by: disposeBag)
        } else {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("Your payment includes a $2.00 convenience fee.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText)\"")
            }).disposed(by: disposeBag)
        }
    }

    func testPaymentAmountFeeFooterLabelTextCardCommercial() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("Your payment includes a 5% convenience fee.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText)\"")
            }).disposed(by: disposeBag)
        } else {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                let expectedFeeString = NSLocalizedString("Your payment includes a $2.00 convenience fee.", comment: "")
                XCTAssert(feeText == expectedFeeString, "Expected \"\(expectedFeeString)\", got \"\(feeText)\"")
            }).disposed(by: disposeBag)
        }
    }

    func testSelectedWalletItemImage() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.selectedWalletItemImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssert(image == #imageLiteral(resourceName: "opco_bank_mini"), "Selected bank account should show opco_bank_mini image")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.selectedWalletItemImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssert(image == #imageLiteral(resourceName: "opco_credit_card_mini"), "Selected credit card should show opco_credit_card_mini image")
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemMaskedAccountString() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.selectedWalletItemMaskedAccountString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssert(str == "**** 1234", "Expected \"**** 1234\", got \"\(str)\"")
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemNickname() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        // No selected wallet item
        viewModel.selectedWalletItemNickname.asObservable().take(1).subscribe(onNext: { nickname in
            XCTAssertNil(nickname, "Expected nil, got \"\(nickname ?? "nil")\"")
        }).disposed(by: disposeBag)

        // Selected wallet item
        viewModel.selectedWalletItem.value = WalletItem(nickName: "Test")
        viewModel.selectedWalletItemNickname.asObservable().take(1).subscribe(onNext: { nickname in
            XCTAssert(nickname == "Test", "Expected \"Test\", got \"\(nickname ?? "nil")\"")
        }).disposed(by: disposeBag)
    }

    func testConvenienceFee() {
        if Environment.shared.opco == .bge {
            // BGE Residential
            var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            XCTAssert(viewModel.convenienceFee == 2, "Expected fee = 2, got fee = \(viewModel.convenienceFee)")

            // BGE Commercial
            accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": false, "CustomerInfo": [:],
                                                "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            XCTAssert(viewModel.convenienceFee == 5, "Expected fee = 5, got fee = \(viewModel.convenienceFee)")
        } else {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            XCTAssert(viewModel.convenienceFee == 2, "Expected fee = 2, got fee = \(viewModel.convenienceFee)")
        }
    }

    func testAmountDueCurrencyString() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.amountDue.value = 0
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssert(string == "$0.00", "Expected string = $0.00, got string = \(string ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 15.29
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssert(string == "$15.29", "Expected string = $15.29, got string = \(string ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 200.999 // Round up
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssert(string == "$201.00", "Expected string = $200.99, got string = \(string ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 13.922 // Round down
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssert(string == "$13.92", "Expected string = $200.99, got string = \(string ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 0.13
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssert(string == "$0.13", "Expected string = $0.13, got string = \(string ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 5
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssert(string == "$5.00", "Expected string = $5.00, got string = \(string ?? "nil")")
        }).disposed(by: disposeBag)
    }

    func testDueDate() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["dueByDate": "2018-08-13T04:45:21"], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.dueDate.asObservable().take(1).subscribe(onNext: { dueDate in
            XCTAssert(dueDate == "08/13/2018", "Expected dueDate = 08/13/2018, got dueDate = \(dueDate ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel.dueDate.asObservable().take(1).subscribe(onNext: { dueDate in
            XCTAssert(dueDate == "--", "Expected dueDate = --, got dueDate = \(dueDate ?? "nil")")
        }).disposed(by: disposeBag)
    }

    func testIsFixedPaymentDate() {
        if Environment.shared.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.accountDetail.value = AccountDetail(activeSeverance: true)
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "Active severance user should have a fixed payment date")
            }).disposed(by: disposeBag)

            viewModel.accountDetail.value = AccountDetail()
            viewModel.allowEdits.value = false
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "allowEdits = false should have a fixed payment date")
            }).disposed(by: disposeBag)
        } else {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.allowEdits.value = false
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "allowEdits = false should have a fixed payment date")
            }).disposed(by: disposeBag)

            var dateComps = DateComponents()
            dateComps.day = -1
            let startOfTodayDate = Calendar.opCo.startOfDay(for: .now)
            let dueByDate = Calendar.opCo.date(byAdding: dateComps, to: startOfTodayDate)
            viewModel.accountDetail.value = AccountDetail(billingInfo: BillingInfo(dueByDate: dueByDate))
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "A due date in the past should have a fixed payment date")
            }).disposed(by: disposeBag)
        }
    }

    func testIsOverpaying() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        if Environment.shared.opco == .bge { // Overpayment is a BGE only concept
            viewModel.amountDue.value = 100
            viewModel.paymentAmount.value = 200
            viewModel.isOverpaying.asObservable().take(1).subscribe(onNext: { overpaying in
                XCTAssert(overpaying, "isOverpaying should be true when amount due = $100 and payment amount = $200")
            }).disposed(by: disposeBag)
        } else {
            viewModel.isOverpaying.asObservable().take(1).subscribe(onNext: { overpaying in
                XCTAssertFalse(overpaying, "isOverpaying should always be false for ComEd/PECO")
            }).disposed(by: disposeBag)
        }
    }

    func testOverpayingValueDisplayString() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.paymentAmount.value = 200
        viewModel.overpayingValueDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssert(str == "$0.00", "Expected $0.00, got \(str ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.paymentAmount.value = 213.88
        viewModel.overpayingValueDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssert(str == "$13.88", "Expected $13.88, got \(str ?? "nil")")
        }).disposed(by: disposeBag)
    }

    func testConvenienceFeeDisplayString() {
        if Environment.shared.opco == .bge {
            // BGE Residential
            var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.convenienceFeeDisplayString.asObservable().take(1).subscribe(onNext: { feeStr in
                XCTAssert(feeStr == "$2.00", "Expected $2.00, got \(feeStr ?? "nil")")
            }).disposed(by: disposeBag)

            // BGE Commercial - Percentage of payment amount
            accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": false, "CustomerInfo": [:],
                                                "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.convenienceFeeDisplayString.asObservable().take(1).subscribe(onNext: { feeStr in
                XCTAssert(feeStr == "$10.00", "Expected $10.00, got \(feeStr ?? "nil")")
            }).disposed(by: disposeBag)
        } else { // ComEd/PECO
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.convenienceFeeDisplayString.asObservable().take(1).subscribe(onNext: { feeStr in
                XCTAssert(feeStr == "$2.00", "Expected $2.00, got \(feeStr ?? "nil")")
            }).disposed(by: disposeBag)
        }
    }

    func testTotalPaymentDisplayString() {
        if Environment.shared.opco == .bge {
            var accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            // Bank workflow, no convenience fee
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.totalPaymentDisplayString.asObservable().take(1).subscribe(onNext: { str in
                XCTAssert(str == "$200.00", "Expected $200.00, got \(str ?? "nil")")
            }).disposed(by: disposeBag)

            // Residential card - fixed fee
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.totalPaymentDisplayString.asObservable().take(1).subscribe(onNext: { str in
                XCTAssert(str == "$202.00", "Expected $202.00, got \(str ?? "nil")")
            }).disposed(by: disposeBag)

            accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": false, "CustomerInfo": [:],
                                                "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            // Commercial card - percentage fee
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.totalPaymentDisplayString.asObservable().take(1).subscribe(onNext: { str in
                XCTAssert(str == "$210.00", "Expected $210.00, got \(str ?? "nil")")
            }).disposed(by: disposeBag)
        } else {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isResidential": false, "CustomerInfo": [:],
                                                "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                "SERInfo": [:]])!
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.totalPaymentDisplayString.asObservable().take(1).subscribe(onNext: { str in
                XCTAssert(str == "$202.00", "Expected $202.00, got \(str ?? "nil")")
            }).disposed(by: disposeBag)
        }
    }

    func testReviewPaymentFooterLabelText() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        if Environment.shared.opco == .bge {
            viewModel.reviewPaymentFooterLabelText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssertNil(text, "Expected nil, got \(text ?? "nil")")
            }).disposed(by: disposeBag)

            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.reviewPaymentFooterLabelText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssertEqual(text, NSLocalizedString("You hereby authorize a payment debit entry to your Credit/Debit/Share Draft account. You understand that if the payment under this authorization is returned or otherwise dishonored, you will promptly remit the payment due plus any fees due under your account.", comment: ""))
            }).disposed(by: disposeBag)
        } else {
            viewModel.reviewPaymentFooterLabelText.asObservable().take(1).subscribe(onNext: { text in
                XCTAssertEqual(text, NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: ""))
            }).disposed(by: disposeBag)
        }
    }

}
