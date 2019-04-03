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
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.fromMockJson(forKey: .residential)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertFalse(self.viewModel.isFetching.value)
            XCTAssertNotNil(self.viewModel.walletItems.value, "walletItems should have been set")
            XCTAssertEqual(self.viewModel.walletItems.value!.count, 2, "2 wallet items should have been returned")
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should have been set to a default")
            XCTAssertEqual(self.viewModel.selectedWalletItem.value!.nickName, "Test Card", "selectedWalletItem should be the default item")
        }, onError: {
            XCTFail("unexpected error response")
        })
    }

    func testFetchDataModifyPayment() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.fromMockJson(forKey: .residential)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)
        viewModel.paymentId.value = "1"

        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertEqual(self.viewModel.paymentAmount.value, 100.00)
            XCTAssertEqual(self.viewModel.paymentDate.value, Date(timeIntervalSince1970: 13), "paymentDate should have been updated from the paymentDetail")
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should have been set to the matching walletId from the paymentDetail")
        }, onError: {
            XCTFail("unexpected error response")
        })
    }

    func testFetchDataCashOnly() {
        // Test 1: Cash only user with a credit card set as default
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.fromMockJson(forKey: .cashOnly)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)

        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should not be nil because default item is credit card")
            XCTAssertEqual(self.viewModel.selectedWalletItem.value!.nickName, "Test Card")
        }, onError: {
            XCTFail("unexpected error response")
        })

        // Test 2: Cash only user with credit cards but none set as default
        MockUser.current = MockUser(globalKeys: .twoCardsNoDefault)
        MockAccountService.loadAccountsSync()
        viewModel.selectedWalletItem.value = nil // Reset
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should not be nil because wallet items include a credit card")
            XCTAssertEqual(self.viewModel.selectedWalletItem.value!.nickName, "Test Card 1")
        }, onError: {
            XCTFail("unexpected error response")
        })
        
        // Test 2: Cash only user with a bank account but no credit cards
        MockUser.current = MockUser(globalKeys: .billCardWithDefaultPayment)
        MockAccountService.loadAccountsSync()
        viewModel.selectedWalletItem.value = nil // Reset
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should be nil because user has no credit cards")
        }, onError: {
            XCTFail("unexpected error response")
        })
    }

    func testSchedulePaymentExistingWalletItem() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.default
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.schedulePayment(onDuplicate: { (title, message) in
            XCTFail("unexpected onDuplicate response")
        }, onSuccess: {
            // Pass
        }, onError: { err in
            XCTFail("unexpected onError response")
        })
    }

    func testCancelPayment() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.default
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)
        viewModel.paymentId.value = "123"
        viewModel.paymentDetail.value = PaymentDetail(walletItemId: "123", paymentAmount: 123, paymentDate: .now)
        viewModel.cancelPayment(onSuccess: {
            // Pass
        }, onError: { err in
            XCTFail("unexpected onError response")
        })
    }

    func testModifyPayment() {
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.default
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, paymentDetail: nil, billingHistoryItem: nil)
        viewModel.paymentId.value = "123"
        viewModel.paymentDetail.value = PaymentDetail(walletItemId: "123", paymentAmount: 123, paymentDate: .now)
        viewModel.selectedWalletItem.value = WalletItem()
        viewModel.modifyPayment(onSuccess: {
            // Pass
        }, onError: { err in
            XCTFail("unexpected onError response")
        })
    }

    func testPaymentFieldsValid() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.paymentAmount.value = 100
        viewModel.paymentFieldsValid.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "paymentFieldsValid should be valid for this test case")
        }).disposed(by: disposeBag)
    }

    func testMakePaymentNextButtonEnabled() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "Payment method view should not be shown by default")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "Payment method view should be shown after a wallet item is selected")
        }).disposed(by: disposeBag)
    }

    func testHasWalletItems() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .cashOnly), paymentDetail: nil, billingHistoryItem: nil)

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
        viewModel.accountDetail.value = .fromMockJson(forKey: .finaledResidential)
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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

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

    func testPaymentAmountFeeLabelTextBank() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeLabelTextCard() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("A $5.95 convenience fee will be applied by Paymentus, our payment partner.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeFooterLabelTextBank() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeFooterLabelTextCardResidential() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("Your payment includes a $5.95 convenience fee.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeFooterLabelTextCardCommercial() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("Your payment includes a $5.95 convenience fee.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemImage() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.selectedWalletItemImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "opco_bank_mini"), "Selected bank account should show opco_bank_mini image")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.value = WalletItem(paymentMethodType: .visa, bankOrCard: .card)
        viewModel.selectedWalletItemImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, UIImage(named: "ic_visa_mini"), "Selected credit card should show ic_visa_mini")
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemMaskedAccountString() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.selectedWalletItemMaskedAccountString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssertEqual(str, "**** 1234")
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemNickname() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        // No selected wallet item
        viewModel.selectedWalletItemNickname.asObservable().take(1).subscribe(onNext: { nickname in
            XCTAssertNil(nickname)
        }).disposed(by: disposeBag)

        // Selected wallet item
        viewModel.selectedWalletItem.value = WalletItem(nickName: "Test")
        viewModel.selectedWalletItemNickname.asObservable().take(1).subscribe(onNext: { nickname in
            XCTAssertEqual(nickname, "Test")
        }).disposed(by: disposeBag)
    }

    func testConvenienceFee() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        XCTAssertEqual(viewModel.convenienceFee, 5.95)
    }

    func testAmountDueCurrencyString() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.amountDue.value = 0
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$0.00")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 15.29
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$15.29")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 200.999 // Round up
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$201.00")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 13.922 // Round down
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$13.92")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 0.13
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$0.13")
        }).disposed(by: disposeBag)

        viewModel.amountDue.value = 5
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$5.00")
        }).disposed(by: disposeBag)
    }

    func testDueDate() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.dueDate.asObservable().take(1).subscribe(onNext: { dueDate in
            XCTAssert(dueDate == "01/11/2019", "Expected dueDate = 01/11/2019, got dueDate = \(dueDate ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.accountDetail.value = .default
        viewModel.dueDate.asObservable().take(1).subscribe(onNext: { dueDate in
            XCTAssert(dueDate == "--", "Expected dueDate = --, got dueDate = \(dueDate ?? "nil")")
        }).disposed(by: disposeBag)
    }

    func testIsFixedPaymentDate() {
        if Environment.shared.opco == .bge {
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .default, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.accountDetail.value = AccountDetail.fromMockJson(forKey: .activeSeverance)
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "Active severance user should have a fixed payment date")
            }).disposed(by: disposeBag)

            viewModel.accountDetail.value = AccountDetail.default
            viewModel.allowEdits.value = false
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "allowEdits = false should have a fixed payment date")
            }).disposed(by: disposeBag)
        } else {
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .default, paymentDetail: nil, billingHistoryItem: nil)

            viewModel.allowEdits.value = false
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "allowEdits = false should have a fixed payment date")
            }).disposed(by: disposeBag)

            viewModel.accountDetail.value = AccountDetail.fromMockJson(forKey: .dueDatePassed)
            viewModel.isFixedPaymentDate.asObservable().take(1).subscribe(onNext: { fixed in
                XCTAssert(fixed, "A due date in the past should have a fixed payment date")
            }).disposed(by: disposeBag)
        }
    }

    func testIsOverpaying() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .default, paymentDetail: nil, billingHistoryItem: nil)

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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.paymentAmount.value = 200
        viewModel.overpayingValueDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssert(str == "$0.00", "Expected $0.00, got \(str ?? "nil")")
        }).disposed(by: disposeBag)

        viewModel.paymentAmount.value = 213.88
        viewModel.overpayingValueDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssert(str == "$13.88", "Expected $13.88, got \(str ?? "nil")")
        }).disposed(by: disposeBag)
    }

    func testTotalPaymentDisplayString() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), paymentDetail: nil, billingHistoryItem: nil)

        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.totalPaymentDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssertEqual(str, "$205.95")
        }).disposed(by: disposeBag)
    }

    func testReviewPaymentFooterLabelText() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .default, paymentDetail: nil, billingHistoryItem: nil)
        
        XCTAssertEqual(viewModel.reviewPaymentFooterLabelText, NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: ""))
    }

}
