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
            if bankWorkflow {
                XCTFail("bankWorkflow should be false initially")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.value = true
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            if bankWorkflow {
                XCTFail("bankWorkflow should be false when inlineCard is true")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.value = false
        viewModel.inlineBank.value = true
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            if !bankWorkflow {
                XCTFail("bankWorkflow should be true when inlineBank is true")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = false
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            if !bankWorkflow {
                XCTFail("bankWorkflow should be true when selectedWalletItem is a bank account")
            }
        }).disposed(by: disposeBag)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.bankWorkflow.asObservable().take(1).subscribe(onNext: { bankWorkflow in
            if bankWorkflow {
                XCTFail("bankWorkflow should be false when selectedWalletItem is a card")
            }
        }).disposed(by: disposeBag)
    }
    
    func testCardWorkflow() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            if cardWorkflow {
                XCTFail("cardWorkflow should be false initially")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = true
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            if cardWorkflow {
                XCTFail("cardWorkflow should be false when inlineBank is true")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = true
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            if !cardWorkflow {
                XCTFail("cardWorkflow should be true when inlineCard is true")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineBank.value = false
        viewModel.inlineCard.value = false
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            if !cardWorkflow {
                XCTFail("cardWorkflow should be true when selectedWalletItem is a card")
            }
        }).disposed(by: disposeBag)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
        viewModel.cardWorkflow.asObservable().take(1).subscribe(onNext: { cardWorkflow in
            if cardWorkflow {
                XCTFail("cardWorkflow should be false when selectedWalletItem is a bank account")
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Inline Bank Validation
    
    func testSaveToWalletBankFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("saveToWalletBankFormValidBGE should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.accountHolderName.value = "Test"
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        addBankFormViewModel.nickname.value = "Test"
        viewModel.saveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("saveToWalletBankFormValidBGE should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSaveToWalletBankFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("testSaveToWalletBankFormValidComEdPECO should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        viewModel.saveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("testSaveToWalletBankFormValidComEdPECO should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletBankFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("noSaveToWalletBankFormValidBGE should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.accountHolderName.value = "Test"
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        viewModel.noSaveToWalletBankFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("noSaveToWalletBankFormValidBGE should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletBankFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("testSaveToWalletBankFormValidComEdPECO should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addBankFormViewModel.routingNumber.value = "123456789"
        addBankFormViewModel.accountNumber.value = "12345"
        addBankFormViewModel.confirmAccountNumber.value = "12345"
        viewModel.noSaveToWalletBankFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("testSaveToWalletBankFormValidComEdPECO should be valid for this test case")
            }
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
                if enteringVisa {
                    XCTFail("1234123412341234 is not a Visa number")
                }
            }).disposed(by: disposeBag)
            
            addCardFormViewModel.cardNumber.value = "4234123412341234"
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                if !enteringVisa {
                    XCTFail("4234123412341234 is a Visa number")
                }
            }).disposed(by: disposeBag)
            
            viewModel.accountDetail.value = AccountDetail.from(["accountNumber": "0123456789", "isResidential": true, "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                if enteringVisa {
                    XCTFail("This test should only occur for Commercial customers")
                }
            }).disposed(by: disposeBag)
        } else {
            addCardFormViewModel.cardNumber.value = "4234123412341234"
            viewModel.bgeCommercialUserEnteringVisa.asObservable().take(1).subscribe(onNext: { enteringVisa in
                if enteringVisa {
                    XCTFail("This test should only occur for BGE users")
                }
            }).disposed(by: disposeBag)
        }
    }
    
    func testSaveToWalletCardFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("saveToWalletCardFormValidBGE should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.nameOnCard.value = "Test"
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        addCardFormViewModel.nickname.value = "Test"
        viewModel.saveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("saveToWalletCardFormValidBGE should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testSaveToWalletCardFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.saveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("saveToWalletCardFormValidBGE should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        addCardFormViewModel.nickname.value = "Test"
        viewModel.saveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("saveToWalletCardFormValidBGE should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletCardFormValidBGE() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("saveToWalletCardFormValidBGE should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.nameOnCard.value = "Test"
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        viewModel.noSaveToWalletCardFormValidBGE.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("saveToWalletCardFormValidBGE should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testNoSaveToWalletCardFormValidComEdPECO() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": [:], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.noSaveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if valid {
                XCTFail("saveToWalletCardFormValidBGE should be invalid initially")
            }
        }).disposed(by: disposeBag)
        
        addCardFormViewModel.cardNumber.value = "5444009999222205"
        addCardFormViewModel.expMonth.value = "02"
        addCardFormViewModel.expYear.value = "2021"
        addCardFormViewModel.cvv.value = "123"
        addCardFormViewModel.zipCode.value = "12345"
        viewModel.noSaveToWalletCardFormValidComEdPECO.asObservable().take(1).subscribe(onNext: { valid in
            if !valid {
                XCTFail("saveToWalletCardFormValidBGE should be valid for this test case")
            }
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
                if !valid {
                    XCTFail("inlineBankValid should be valid for this test case")
                }
            }).disposed(by: disposeBag)
            
            addBankFormViewModel.saveToWallet.value = false
            addBankFormViewModel.nickname.value = ""
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                if !valid {
                    XCTFail("inlineBankValid should be valid for this test case")
                }
            }).disposed(by: disposeBag)
        } else {
            addBankFormViewModel.saveToWallet.value = true
            addBankFormViewModel.routingNumber.value = "123456789"
            addBankFormViewModel.accountNumber.value = "12345"
            addBankFormViewModel.confirmAccountNumber.value = "12345"
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                if !valid {
                    XCTFail("inlineBankValid should be valid for this test case")
                }
            }).disposed(by: disposeBag)
            
            addBankFormViewModel.saveToWallet.value = false
            viewModel.inlineBankValid.asObservable().take(1).subscribe(onNext: { valid in
                if !valid {
                    XCTFail("inlineBankValid should be valid for this test case")
                }
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
                if !valid {
                    XCTFail("inlineCardValid should be valid for this test case")
                }
            }).disposed(by: disposeBag)
            
            addCardFormViewModel.saveToWallet.value = false
            addCardFormViewModel.nickname.value = ""
            viewModel.inlineCardValid.asObservable().take(1).subscribe(onNext: { valid in
                if !valid {
                    XCTFail("inlineCardValid should be valid for this test case")
                }
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
                if !valid {
                    XCTFail("inlineCardValid should be valid for this test case")
                }
            }).disposed(by: disposeBag)
            
            addCardFormViewModel.saveToWallet.value = false
            viewModel.inlineCardValid.asObservable().take(1).subscribe(onNext: { valid in
                if !valid {
                    XCTFail("inlineCardValid should be valid for this test case")
                }
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
            if !valid {
                XCTFail("paymentFieldsValid should be valid for this test case")
            }
        }).disposed(by: disposeBag)
    }
    
    func testMakePaymentNextButtonEnabled() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        // Initial state
        viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
            if enabled {
                XCTFail("Next button should not be enabled initially")
            }
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
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
            }).disposed(by: disposeBag)
        } else {
            addBankFormViewModel.routingNumber.value = "123456789"
            addBankFormViewModel.accountNumber.value = "12345"
            addBankFormViewModel.confirmAccountNumber.value = "12345"
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
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
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
            }).disposed(by: disposeBag)
        } else {
            addCardFormViewModel.cardNumber.value = "5444009999222205"
            addCardFormViewModel.expMonth.value = "02"
            addCardFormViewModel.expYear.value = "2021"
            addCardFormViewModel.cvv.value = "123"
            addCardFormViewModel.zipCode.value = "12345"
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
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
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
            }).disposed(by: disposeBag)
            
            // Bank
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
            }).disposed(by: disposeBag)
        } else {
            viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .bank)
            viewModel.makePaymentNextButtonEnabled.asObservable().take(1).subscribe(onNext: { enabled in
                if !enabled {
                    XCTFail("Next button should be enabled for this test case")
                }
            }).disposed(by: disposeBag)
        }
        
    }
    
    func testShouldShowNextButton() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.shouldShowNextButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            if !shouldShow {
                XCTFail("Next button should show by default")
            }
        }).disposed(by: disposeBag)
        
        viewModel.paymentId.value = "123"
        viewModel.allowEdits.value = false
        viewModel.shouldShowNextButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            if shouldShow {
                XCTFail("Next button should not show when allowEdits is false")
            }
        }).disposed(by: disposeBag)
        
        viewModel.allowEdits.value = true
        viewModel.shouldShowNextButton.asObservable().take(1).subscribe(onNext: { shouldShow in
            if !shouldShow {
                XCTFail("Next button should show when allowEdits is true")
            }
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowPaymentAccountView() {
        let accountDetail = AccountDetail.from(["accountNumber": "0123456789", "CustomerInfo": [:], "BillingInfo": ["netDueAmount": 200], "SERInfo": [:]])!
        addBankFormViewModel = AddBankFormViewModel(walletService: MockWalletService())
        addCardFormViewModel = AddCardFormViewModel(walletService: MockWalletService())
        viewModel = PaymentViewModel(walletService: MockWalletService(), paymentService: MockPaymentService(), accountDetail: accountDetail, addBankFormViewModel: addBankFormViewModel, addCardFormViewModel: addCardFormViewModel, paymentDetail: nil, billingHistoryItem: nil)
        
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            if shouldShow {
                XCTFail("Payment account view should not be shown by default")
            }
        }).disposed(by: disposeBag)
        
        viewModel.selectedWalletItem.value = WalletItem(bankOrCard: .card)
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            if !shouldShow {
                XCTFail("Payment account view should be shown after a wallet item is selected")
            }
        }).disposed(by: disposeBag)
        
        viewModel.inlineCard.value = true
        viewModel.shouldShowPaymentAccountView.asObservable().take(1).subscribe(onNext: { shouldShow in
            if shouldShow {
                XCTFail("Payment account view should not be shown if entering an inline card or bank")
            }
        }).disposed(by: disposeBag)
    }
    
    
    
}
