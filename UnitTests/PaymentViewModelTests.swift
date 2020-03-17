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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, billingHistoryItem: nil)

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

    func testFetchDataCashOnly() {
        // Test 1: Cash only user with a credit card set as default
        MockUser.current = MockUser.default
        MockAccountService.loadAccountsSync()
        
        let accountDetail = AccountDetail.fromMockJson(forKey: .cashOnly)
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, billingHistoryItem: nil)

        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should not be nil because default item is credit card")
            XCTAssertEqual(self.viewModel.selectedWalletItem.value!.nickName, "Test Card")
        }, onError: {
            XCTFail("unexpected error response")
        })

        // Test 2: Cash only user with credit cards but none set as default
        MockUser.current = MockUser(globalKeys: .twoCardsNoDefault)
        MockAccountService.loadAccountsSync()
        viewModel.selectedWalletItem.accept(nil) // Reset
        viewModel.fetchData(initialFetch: true, onSuccess: {
            XCTAssertNotNil(self.viewModel.selectedWalletItem.value, "selectedWalletItem should not be nil because wallet items include a credit card")
            XCTAssertEqual(self.viewModel.selectedWalletItem.value!.nickName, "Test Card 1")
        }, onError: {
            XCTFail("unexpected error response")
        })
        
        // Test 2: Cash only user with a bank account but no credit cards
        MockUser.current = MockUser(globalKeys: .billCardWithDefaultPayment)
        MockAccountService.loadAccountsSync()
        viewModel.selectedWalletItem.accept(nil) // Reset
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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, billingHistoryItem: nil)
        viewModel.selectedWalletItem.accept(WalletItem())
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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, billingHistoryItem: nil)
        viewModel.paymentId.accept("123")
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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, billingHistoryItem: nil)
        viewModel.paymentId.accept("123")
        viewModel.selectedWalletItem.accept(WalletItem())
        viewModel.modifyPayment(onSuccess: {
            // Pass
        }, onError: { err in
            XCTFail("unexpected onError response")
        })
    }

    func testPaymentFieldsValid() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.paymentAmount.accept(100)
        var dateComps = DateComponents(calendar: .opCo, year: 2019, month: 1, day: 2)
        viewModel.paymentDate.accept(dateComps.date!)
        viewModel.selectedWalletItem.accept(WalletItem())
        viewModel.paymentFieldsValid.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "paymentFieldsValid should be true for this test case")
        }).disposed(by: disposeBag)
        
        dateComps = DateComponents(calendar: .opCo, year: 2019, month: 12, day: 2)
        viewModel.paymentDate.accept(dateComps.date!)
        viewModel.paymentFieldsValid.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "paymentFieldsValid should be false when the date is past the due date (ComEd/PECO) or more than 180 days out (BGE - bank account)")
        }).disposed(by: disposeBag)
    }

    func testMakePaymentNextButtonEnabled() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        // Initial state
        viewModel.makePaymentContinueButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            XCTAssertFalse(enabled, "Continue button should not be enabled initially")
        }).disposed(by: disposeBag)

        // TODO: Make this test more robust
    }

    func testShouldShowPaymentAccountView() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.shouldShowPaymentMethodButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "Payment method button should not be shown by default")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.accept(WalletItem(paymentMethodType: .visa))
        viewModel.shouldShowPaymentMethodButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "Payment method button should be shown after a wallet item is selected")
        }).disposed(by: disposeBag)
    }

    func testHasWalletItems() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .cashOnly), billingHistoryItem: nil)

        // Cash only user test - bank accounts should be ignored
        viewModel.walletItems.accept([WalletItem(), WalletItem()])
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssertFalse(hasWalletItems, "hasWalletItems should be false for a cash only user with only include bank accounts")
        }).disposed(by: disposeBag)
        var newValue = viewModel.walletItems.value
        newValue?.append(WalletItem(paymentMethodType: .visa))
        viewModel.walletItems.accept(newValue)
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssert(hasWalletItems, "hasWalletItems should be true for a cash only user with a credit card")
        }).disposed(by: disposeBag)

        // Normal test case
        viewModel.accountDetail.accept(.fromMockJson(forKey: .finaledResidential))
        viewModel.walletItems.accept([])
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssertFalse(hasWalletItems, "hasWalletItems should be false for a normal scenario with no wallet items")
        }).disposed(by: disposeBag)
        viewModel.walletItems.accept([WalletItem(), WalletItem(paymentMethodType: .visa)])
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssert(hasWalletItems, "hasWalletItems should be true for a normal scenario with wallet items")
        }).disposed(by: disposeBag)
    }

    func testShouldShowPaymentAmountTextField() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        // Editing payment
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(!shouldShow, "paymentAmountTextField should not show when no wallet items + not editing")
        }).disposed(by: disposeBag)

        // Has Wallet Items
        viewModel.walletItems.accept([WalletItem()])
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "paymentAmountTextField should show when user has wallet items")
        }).disposed(by: disposeBag)
        
        viewModel.walletItems.accept(nil)
        viewModel.paymentId.accept("123")
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "paymentAmountTextField should show when user is editing")
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeLabelTextBank() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)
        
        viewModel.selectedWalletItem.accept(WalletItem())
        viewModel.paymentMethodFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeLabelTextCard() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.selectedWalletItem.accept(WalletItem(paymentMethodType: .visa))
        viewModel.paymentMethodFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("A $5.95 convenience fee will be applied by Paymentus, our payment partner.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeFooterLabelTextBank() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)
        
        viewModel.selectedWalletItem.accept(WalletItem())
        viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("No convenience fee will be applied.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeFooterLabelTextCardResidential() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.selectedWalletItem.accept(WalletItem(paymentMethodType: .visa))
        viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("Your payment includes a $5.95 convenience fee.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testPaymentAmountFeeFooterLabelTextCardCommercial() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.selectedWalletItem.accept(WalletItem(paymentMethodType: .visa))
        viewModel.paymentAmountFeeFooterLabelText.asObservable().take(1).subscribe(onNext: { feeText in
            let expectedFeeString = NSLocalizedString("Your payment includes a $5.95 convenience fee.", comment: "")
            XCTAssertEqual(feeText, expectedFeeString)
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemImage() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.selectedWalletItem.accept(WalletItem())
        viewModel.selectedWalletItemImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, #imageLiteral(resourceName: "opco_bank_mini"), "Selected bank account should show opco_bank_mini image")
        }).disposed(by: disposeBag)

        viewModel.selectedWalletItem.accept(WalletItem(paymentMethodType: .visa))
        viewModel.selectedWalletItemImage.asObservable().take(1).subscribe(onNext: { image in
            XCTAssertEqual(image, UIImage(named: "ic_visa_mini"), "Selected credit card should show ic_visa_mini")
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemMaskedAccountString() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.selectedWalletItem.accept(WalletItem())
        viewModel.selectedWalletItemMaskedAccountString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssertEqual(str, "**** 1234")
        }).disposed(by: disposeBag)
    }

    func testSelectedWalletItemNickname() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        // No selected wallet item
        viewModel.selectedWalletItemNickname.asObservable().take(1).subscribe(onNext: { nickname in
            XCTAssertNil(nickname)
        }).disposed(by: disposeBag)

        // Selected wallet item
        viewModel.selectedWalletItem.accept(WalletItem(nickName: "Test"))
        viewModel.selectedWalletItemNickname.asObservable().take(1).subscribe(onNext: { nickname in
            XCTAssertEqual(nickname, "Test")
        }).disposed(by: disposeBag)
    }

    func testConvenienceFee() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        XCTAssertEqual(viewModel.convenienceFee, 5.95)
    }

    func testAmountDueCurrencyString() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.amountDue.accept(0)
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$0.00")
        }).disposed(by: disposeBag)

        viewModel.amountDue.accept(15.29)
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$15.29")
        }).disposed(by: disposeBag)

        viewModel.amountDue.accept(200.999) // Round up
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$201.00")
        }).disposed(by: disposeBag)

        viewModel.amountDue.accept(13.922) // Round down
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$13.92")
        }).disposed(by: disposeBag)

        viewModel.amountDue.accept(0.13)
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$0.13")
        }).disposed(by: disposeBag)

        viewModel.amountDue.accept(5)
        viewModel.amountDueCurrencyString.asObservable().take(1).subscribe(onNext: { string in
            XCTAssertEqual(string, "$5.00")
        }).disposed(by: disposeBag)
    }

    func testDueDate() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.dueDate.asObservable().take(1).subscribe(onNext: { dueDate in
            XCTAssertEqual(dueDate, "01/11/2019")
        }).disposed(by: disposeBag)

        viewModel.accountDetail.accept(.default)
        viewModel.dueDate.asObservable().take(1).subscribe(onNext: { dueDate in
            XCTAssertEqual(dueDate, "--")
        }).disposed(by: disposeBag)
    }
    
    func testComputeDefaultPaymentDate() {
        // TODO: Reimplement this test (rules are currently in flux so not worth it right now)
    }

    func testCanEditPaymentDate() {
        // TODO: Reimplement this test (rules are currently in flux so not worth it right now)
    }

    func testIsOverpaying() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .default, billingHistoryItem: nil)

        if Environment.shared.opco == .bge { // Overpayment is a BGE only concept
            viewModel.amountDue.accept(100)
            viewModel.paymentAmount.accept(200)
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
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.paymentAmount.accept(200)
        viewModel.overpayingValueDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssertEqual(str, "$0.00")
        }).disposed(by: disposeBag)

        viewModel.paymentAmount.accept(213.88)
        viewModel.overpayingValueDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssertEqual(str, "$13.88")
        }).disposed(by: disposeBag)
    }

    func testTotalPaymentDisplayString() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .fromMockJson(forKey: .billCardNoDefaultPayment), billingHistoryItem: nil)

        viewModel.selectedWalletItem.accept(WalletItem(paymentMethodType: .visa))
        viewModel.paymentAmount.accept(200)
        viewModel.totalPaymentDisplayString.asObservable().take(1).subscribe(onNext: { str in
            XCTAssertEqual(str, "$205.95")
        }).disposed(by: disposeBag)
    }

    func testReviewPaymentFooterLabelText() {
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: .default, billingHistoryItem: nil)
        
        XCTAssertEqual(viewModel.reviewPaymentFooterLabelText, NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: ""))
    }

}
