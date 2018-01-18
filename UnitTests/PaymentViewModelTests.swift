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
    var addBankFormViewModel: AddBankFormViewModel!
    var addCardFormViewModel: AddCardFormViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testBankWorkflow() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            XCTAssertFalse(bankWorkflow, "bankWorkflow should be false initially")
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.value = true
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            XCTAssertFalse(bankWorkflow, "bankWorkflow should be false when inlineCard is true")
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.value = false
        viewModel.inlineBank.value = true
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            XCTAssert(bankWorkflow, "bankWorkflow should be true when inlineBank is true")
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = false
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
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssertFalse(cardWorkflow, "cardWorkflow should be false initially")
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = true
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssertFalse(cardWorkflow, "cardWorkflow should be false when inlineBank is true")
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = true
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssert(cardWorkflow, "cardWorkflow should be true when inlineCard is true")
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = false
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssert(cardWorkflow, "cardWorkflow should be true when selectedWalletItem is a card")
        }).disposed(by: disposeBag)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            XCTAssertFalse(cardWorkflow, "cardWorkflow should be false when selectedWalletItem is a bank account")
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Inline Bank Validation
    
    func testSaveToWalletBankFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "saveToWalletBankFormValidBGE should be invalid initially")
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.accountHolderName.value = "Test"
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        addBankFormViewModel.nickname.value = "Test"
        viewModel.saveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "saveToWalletBankFormValidBGE should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testSaveToWalletBankFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "testSaveToWalletBankFormValidComEdPECO should be invalid initially")
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        viewModel.saveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "testSaveToWalletBankFormValidComEdPECO should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletBankFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, ("noSaveToWalletBankFormValidBGE should be invalid initially"))
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.accountHolderName.value = "Test"
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        viewModel.noSaveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "noSaveToWalletBankFormValidBGE should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletBankFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "testSaveToWalletBankFormValidComEdPECO should be invalid initially")
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        viewModel.noSaveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "testSaveToWalletBankFormValidComEdPECO should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Inline Card Validation
    
    func testBgeCommercialUserEnteringVisa() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        if Environment.sharedInstance.opco == .bge {
            addCardFormViewModel.cardNumber.value = "1234123412341234"
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                XCTAssertFalse(enteringVisa, "1234123412341234 is not a Visa number")
            }).disposed(by: disposeBag)
            
            addCardFormViewModel.cardNumber.value = "4234123412341234"
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                XCTAssert(enteringVisa, ("4234123412341234 is a Visa number"))
            }).disposed(by: disposeBag)
            
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                XCTAssertFalse(enteringVisa, "This test should only occur for Commercial customers")
            }).disposed(by: disposeBag)
        } else {
            addCardFormViewModel.cardNumber.value = "4234123412341234"
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                XCTAssertFalse(enteringVisa, "This test should only occur for BGE users")
            }).disposed(by: disposeBag)
        }
    }
    
    func testSaveToWalletCardFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "saveToWalletCardFormValidBGE should be invalid initially")
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.nameOnCard.value = "Test"
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        addCardFormViewModel.nickname.value = "Test"
        viewModel.saveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "saveToWalletCardFormValidBGE should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testSaveToWalletCardFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "saveToWalletCardFormValidBGE should be invalid initially")
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        addCardFormViewModel.nickname.value = "Test"
        viewModel.saveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "saveToWalletCardFormValidBGE should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletCardFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "saveToWalletCardFormValidBGE should be invalid initially")
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.nameOnCard.value = "Test"
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        viewModel.noSaveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "saveToWalletCardFormValidBGE should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletCardFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssertFalse(valid, "saveToWalletCardFormValidBGE should be invalid initially")
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        viewModel.noSaveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "saveToWalletCardFormValidBGE should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testInlineBankValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        if Environment.sharedInstance.opco == .bge {
            addBankFormViewModel.saveToWallet.value = true
            addBankFormViewModel.accountHolderName.value = "Test"
            addBankFormViewModel.routingNumber.value = "123456789"
            addBankFormViewModel.accountNumber.value = "12345"
            addBankFormViewModel.confirmAccountNumber.value = "12345"
            addBankFormViewModel.nickname.value = "Test"
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineBankValid should be valid for this test case")
            }).disposed(by: disposeBag)
            
            addBankFormViewModel.saveToWallet.value = false
            addBankFormViewModel.nickname.value = ""
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineBankValid should be valid for this test case")
            }).disposed(by: disposeBag)
        } else {
            addBankFormViewModel.saveToWallet.value = true
            addBankFormViewModel.routingNumber.value = "123456789"
            addBankFormViewModel.accountNumber.value = "12345"
            addBankFormViewModel.confirmAccountNumber.value = "12345"
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineBankValid should be valid for this test case")
            }).disposed(by: disposeBag)
            
            addBankFormViewModel.saveToWallet.value = false
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineBankValid should be valid for this test case")
            }).disposed(by: disposeBag)
        }
    }
    
    func testInlineCardValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        if Environment.sharedInstance.opco == .bge {
            addCardFormViewModel.saveToWallet.value = true
            addCardFormViewModel.nameOnCard.value = "Test"
            addCardFormViewModel.cardNumber.value = "5444009999222205"
            addCardFormViewModel.expMonth.value = "02"
            addCardFormViewModel.expYear.value = "2021"
            addCardFormViewModel.cvv.value = "123"
            addCardFormViewModel.zipCode.value = "12345"
            addCardFormViewModel.nickname.value = "Test"
            viewModel.inlineCardValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineCardValid should be valid for this test case")
            }).disposed(by: disposeBag)
            
            addCardFormViewModel.saveToWallet.value = false
            addCardFormViewModel.nickname.value = ""
            viewModel.inlineCardValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineCardValid should be valid for this test case")
            }).disposed(by: disposeBag)
        } else {
            addCardFormViewModel.saveToWallet.value = true
            addCardFormViewModel.cardNumber.value = "5444009999222205"
            addCardFormViewModel.expMonth.value = "02"
            addCardFormViewModel.expYear.value = "2021"
            addCardFormViewModel.cvv.value = "123"
            addCardFormViewModel.zipCode.value = "12345"
            addCardFormViewModel.nickname.value = "Test"
            viewModel.inlineCardValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineCardValid should be valid for this test case")
            }).disposed(by: disposeBag)
            
            addCardFormViewModel.saveToWallet.value = false
            viewModel.inlineCardValid.asObservable().take(1).subscribe(onNext: { valid in
                XCTAssert(valid, "inlineCardValid should be valid for this test case")
            }).disposed(by: disposeBag)
        }
    }
    
    func testPaymentFieldsValid() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.paymentAmount.value = "100"
        viewModel.paymentFieldsValid.asObservable().take(1).subscribe(onNext: { valid in
            XCTAssert(valid, "paymentFieldsValid should be valid for this test case")
        }).disposed(by: disposeBag)
    }
    
    func testMakePaymentNextButtonEnabled() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        // Initial state
        viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            XCTAssertFalse(enabled, "Next button should not be enabled initially")
        }).disposed(by: disposeBag)
        
        // Inline bank
        viewModel.inlineBank.value = true
        viewModel.paymentAmount.value = "100"
        if Environment.sharedInstance.opco == .bge {
            addBankFormViewModel.accountHolderName.value = "Test"
            addBankFormViewModel.routingNumber.value = "123456789"
            addBankFormViewModel.accountNumber.value = "12345"
            addBankFormViewModel.confirmAccountNumber.value = "12345"
            addBankFormViewModel.saveToWallet.value = false
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
        } else {
            addBankFormViewModel.routingNumber.value = "123456789"
            addBankFormViewModel.accountNumber.value = "12345"
            addBankFormViewModel.confirmAccountNumber.value = "12345"
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
        }
        
        // Inline card
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = true
        if Environment.sharedInstance.opco == .bge {
            addCardFormViewModel.nameOnCard.value = "Test"
            addCardFormViewModel.cardNumber.value = "5444009999222205"
            addCardFormViewModel.expMonth.value = "02"
            addCardFormViewModel.expYear.value = "2021"
            addCardFormViewModel.cvv.value = "123"
            addCardFormViewModel.zipCode.value = "12345"
            addCardFormViewModel.saveToWallet.value = false
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
        } else {
            addCardFormViewModel.cardNumber.value = "5444009999222205"
            addCardFormViewModel.expMonth.value = "02"
            addCardFormViewModel.expYear.value = "2021"
            addCardFormViewModel.cvv.value = "123"
            addCardFormViewModel.zipCode.value = "12345"
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
        }
        
        // Existing wallet item
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = false
        if Environment.sharedInstance.opco == .bge {
            // Card
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.cvv.value = "123"
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
            
            // Bank
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
        } else {
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                XCTAssert(enabled, "Next button should be enabled for this test case")
            }).disposed(by: disposeBag)
        }
        
    }
    
    func testShouldShowNextButton() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
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
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "Payment account view should not be shown by default")
        }).disposed(by: disposeBag)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "Payment account view should be shown after a wallet item is selected")
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.value = true
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "Payment account view should not be shown if entering an inline card or bank")
        }).disposed(by: disposeBag)
    }
    
    func testHasWalletItems() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "isCashOnly": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        // Cash only user test - bank accounts should be ignored
        viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank)]
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssertFalse(hasWalletItems, "hasWalletItems should be false for a cash only user with only include bank accounts")
        }).disposed(by: disposeBag)
        viewModel.walletItems.value!.append(WalletItem(bankOrCard: .card))
        viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
            XCTAssert(hasWalletItems, "hasWalletItems should be true for a cash only user with a credit card")
        }).disposed(by: disposeBag)
        
        // BGE commercial user test - VISA cards should be ignored
        if Environment.sharedInstance.opco == .bge {
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": false, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel.walletItems.value = [WalletItem.initVisaCard()]
            viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
                XCTAssertFalse(hasWalletItems, "hasWalletItems should be false for a BGE commercial user with only Visa cards")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value!.append(WalletItem(bankOrCard: .bank))
            viewModel.hasWalletItems.asObservable().take(1).subscribe(onNext: { hasWalletItems in
                XCTAssert(hasWalletItems, "hasWalletItems should be true for a BGE commercial user with a bank account")
            }).disposed(by: disposeBag)
        }
        
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
    
    func testShouldShowCvvTextField() {
        if Environment.sharedInstance.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
            viewModel.shouldShowCvvTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
                XCTAssert(shouldShow, "shouldShowCvvTextField should be true for a BGE user who selected a wallet item and who is not modifying a payment")
            }).disposed(by: disposeBag)
        }
    }
    
    func testCvvIsCorrectLength() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext: { correct in
            XCTAssertFalse(correct, "cvvIsCorrectLength should be false initially")
        }).disposed(by: disposeBag)
        
        viewModel.cvv.value = "123"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext: { correct in
            XCTAssert(correct, "cvvIsCorrectLength should be true for CVV \"123\"")
        }).disposed(by: disposeBag)
        
        viewModel.cvv.value = "1234"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext: { correct in
            XCTAssert(correct, "cvvIsCorrectLength should be true for CVV \"1234\"")
        }).disposed(by: disposeBag)
        
        viewModel.cvv.value = "12345"
        viewModel.cvvIsCorrectLength.asObservable().take(1).subscribe(onNext: { correct in
            XCTAssertFalse(correct, "cvvIsCorrectLength should be false for CVV \"12345\"")
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowPaymentAmountTextField() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
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
        
        // Inline Bank
        viewModel.walletItems.value = []
        viewModel.inlineBank.value = true
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "paymentAmountTextField should show when user is entering a bank inline")
        }).disposed(by: disposeBag)
        
        // Inline Card
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = true
        viewModel.shouldShowPaymentAmountTextField.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "paymentAmountTextField should show when user is entering a card inline")
        }).disposed(by: disposeBag)
    }
    
    // Test paymentAmountErrorMessage for BGE bank accounts when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageBGEBankFromAccountDetail() {
        if Environment.sharedInstance.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "minimumPaymentAmountACH": 0.001, "maximumPaymentAmountACH": 1_500_000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineBank.value = true
            viewModel.paymentAmount.value = "0.0009"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "1600000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "0.001"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "1500000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for ComEd/PECO bank accounts when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageComEdPECOBankFromAccountDetail() {
        if Environment.sharedInstance.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 20_000, "minimumPaymentAmountACH": 3, "maximumPaymentAmountACH": 10_000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineBank.value = true
            viewModel.paymentAmount.value = "2"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "11000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "3"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "10000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
            
            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = "900"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for BGE credit cards when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageBGECardFromAccountDetail() {
        if Environment.sharedInstance.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "minimumPaymentAmount": 0.001, "maximumPaymentAmount": 30000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineCard.value = true
            viewModel.paymentAmount.value = "0.0009"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "31000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "0.001"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "30000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for ComEd/PECO credit cards when the min/max values are defined in accountDetail
    // Min/max values are set below/above the hardcoded fallback values to test that those values are not used when being overridden in accountDetail
    func testPaymentAmountErrorMessageComEdPECOCardFromAccountDetail() {
        if Environment.sharedInstance.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 20_000, "minimumPaymentAmount": 3, "maximumPaymentAmount": 6000],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineCard.value = true
            viewModel.paymentAmount.value = "2"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "7000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "3"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "6000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
            
            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = "900"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for BGE bank accounts when using the hardcoded min/max values
    func testPaymentAmountErrorMessageBGEBankHardcoded() {
        if Environment.sharedInstance.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineBank.value = true
            viewModel.paymentAmount.value = "0"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            // Commercial max
            viewModel.paymentAmount.value = "1000000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "0.01"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            // Commercial max
            viewModel.paymentAmount.value = "999999.99"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
            
            // Residential max
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel.paymentAmount.value = "100000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            // Residential max
            viewModel.paymentAmount.value = "99999.99"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for ComEd/PECO bank accounts when using the hardcoded min/max values
    func testPaymentAmountErrorMessageComEdPECOBankHardcoded() {
        if Environment.sharedInstance.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 100000], "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineBank.value = true
            viewModel.paymentAmount.value = "4"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "100000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "5"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "90000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
            
            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = "900"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for BGE credit cards when using the hardcoded min/max values
    func testPaymentAmountErrorMessageBGECardHardcoded() {
        if Environment.sharedInstance.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineCard.value = true
            viewModel.paymentAmount.value = "0.009"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            // Commercial max
            viewModel.paymentAmount.value = "26000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "0.01"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            // Commercial max
            viewModel.paymentAmount.value = "25000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
            
            // Residential max
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
            viewModel.paymentAmount.value = "700"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            // Residential max
            viewModel.paymentAmount.value = "600"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
        }
    }
    
    // Test paymentAmountErrorMessage for ComEd/PECO credit cards when using the hardcoded min/max values
    func testPaymentAmountErrorMessageComEdPECOCardHardcoded() {
        if Environment.sharedInstance.opco != .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 20_000], "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            viewModel.inlineCard.value = true
            viewModel.paymentAmount.value = "4"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is below minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "6000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when payment is above maximum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "5"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches minimum")
            }).disposed(by: disposeBag)
            
            viewModel.paymentAmount.value = "5000"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNil(err, "paymentAmountErrorMessage should be nil when payment matches maximum")
            }).disposed(by: disposeBag)
            
            // Test overpayment
            viewModel.amountDue.value = 800
            viewModel.paymentAmount.value = "900"
            viewModel.paymentAmountErrorMessage.asObservable().take(1).subscribe(onNext: { err in
                XCTAssertNotNil(err, "paymentAmountErrorMessage should not be nil when overpaying")
            }).disposed(by: disposeBag)
        }
    }
    
    func testPaymentAmountFeeLabelTextBank() {
        if Environment.sharedInstance.opco == .bge {
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "feeResidential": 2, "feeCommercial": 5],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            // Bank account test
            viewModel.inlineBank.value = true
            viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                XCTAssert(feeText == NSLocalizedString("No convenience fee will be applied.", comment: ""))
            }).disposed(by: disposeBag)
        } else { // ComEd/PECO
            let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:],
                                                    "BillingInfo": ["netDueAmount": 200, "convenienceFee": 2],
                                                    "SERInfo": [:]])!
            addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
            addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
            viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
            
            // Bank account test
            viewModel.inlineBank.value = true
            viewModel.paymentAmountFeeLabelText.asObservable().take(1).subscribe(onNext: { feeText in
                XCTAssert(feeText == NSLocalizedString("No convenience fee will be applied.", comment: ""))
            }).disposed(by: disposeBag)
        }
    }

    
}
