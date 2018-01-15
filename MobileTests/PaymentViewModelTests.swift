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
    
}
