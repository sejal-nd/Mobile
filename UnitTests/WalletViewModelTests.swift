//
//  WalletViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class WalletViewModelTests: XCTestCase {
    var viewModel: WalletViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        viewModel = WalletViewModel(walletService: MockWalletService())
    }
    
    func testFetchingWalletItems() {
        AccountsStore.sharedInstance.currentAccount = Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!
        
        let scheduler = TestScheduler(initialClock: 0)
        let events: [Recorded<Event<Void>>] = [next(2, ())]
        let fetch = scheduler.createHotObservable(events)
        fetch.bind(to: viewModel.fetchWalletItems).disposed(by: disposeBag)
        
        scheduler.start()
        viewModel.isFetchingWalletItems.asObservable().take(1).subscribe(onNext: { isFetching in
            XCTAssert(isFetching, "isFetchingWalletItems should be true right after triggering fetch")
        }).disposed(by: disposeBag)

    }
    
    func testShouldShowEmptyState() {
        viewModel.walletItems.value = []
        viewModel.shouldShowEmptyState.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "shouldShowEmptyState should be true with empty walletItems array")
        }).disposed(by: disposeBag)
        
        viewModel.walletItems.value!.append(WalletItem())
        viewModel.shouldShowEmptyState.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowEmptyState should be false with walletItems.count > 0")
        }).disposed(by: disposeBag)
    }
    
    func testShouldShowWalletState() {
        viewModel.walletItems.value = []
        viewModel.shouldShowWallet.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssertFalse(shouldShow, "shouldShowEmptyState should be false with empty walletItems array")
        }).disposed(by: disposeBag)
        
        viewModel.walletItems.value!.append(WalletItem())
        viewModel.shouldShowWallet.asObservable().take(1).subscribe(onNext: { shouldShow in
            XCTAssert(shouldShow, "shouldShowEmptyState should be true with walletItems.count > 0")
        }).disposed(by: disposeBag)
    }
    
    func testCreditCardLimitReached() {
        if Environment.sharedInstance.opco == .bge {
            var walletItems = [WalletItem]()
            for _ in 0..<100 {
                walletItems.append(WalletItem(bankOrCard: .card))
            }
            viewModel.walletItems.value = walletItems
            viewModel.creditCardLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "BGE has no credit card limit - should always return false")
            }).disposed(by: disposeBag)
        } else { // ComEd/PECO have a 3 card limit
            viewModel.creditCardLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "creditCardLimitReached should be false initially")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value = []
            viewModel.creditCardLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "creditCardLimitReached should be false with empty walletItems array")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .card), WalletItem(bankOrCard: .card)]
            viewModel.creditCardLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "creditCardLimitReached should be false with only 2 credit cards")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value = [WalletItem(bankOrCard: .card), WalletItem(bankOrCard: .card), WalletItem(bankOrCard: .card), WalletItem(bankOrCard: .bank)]
            viewModel.creditCardLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssert(limitReached, "creditCardLimitReached should be true with 3 credit cards")
            }).disposed(by: disposeBag)
        }
    }
    
    func testBankAccountLimitReached() {
        if Environment.sharedInstance.opco == .bge {
            var walletItems = [WalletItem]()
            for _ in 0..<100 {
                walletItems.append(WalletItem(bankOrCard: .bank))
            }
            viewModel.walletItems.value = walletItems
            viewModel.bankAccountLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "BGE has no bank account limit - should always return false")
            }).disposed(by: disposeBag)
        } else { // ComEd/PECO have a 3 account limit
            viewModel.bankAccountLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "bankAccountLimitReached should be false initially")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value = []
            viewModel.bankAccountLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "bankAccountLimitReached should be false with empty walletItems array")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .card), WalletItem(bankOrCard: .card)]
            viewModel.bankAccountLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssertFalse(limitReached, "bankAccountLimitReached should be false with only 2 bank accounts")
            }).disposed(by: disposeBag)
            
            viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .card)]
            viewModel.bankAccountLimitReached.asObservable().take(1).subscribe(onNext: { limitReached in
                XCTAssert(limitReached, "bankAccountLimitReached should be true with 3 bank accounts")
            }).disposed(by: disposeBag)
        }
    }
    
    func testAddBankDisabled() {
        if Environment.sharedInstance.opco != .bge {
            viewModel.walletItems.value = [WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .bank), WalletItem(bankOrCard: .card)]
            viewModel.addBankDisabled.asObservable().take(1).subscribe(onNext: { disabled in
                XCTAssert(disabled, "addBankDisabled should be true for ComEd/PECO user with 3 bank accounts")
            }).disposed(by: disposeBag)
        }
        
        viewModel.walletItems.value = []
        viewModel.accountDetail = AccountDetail()
        viewModel.addBankDisabled.asObservable().take(1).subscribe(onNext: { disabled in
            XCTAssertFalse(disabled, "addBankDisabled should be false for non-cash only users")
        }).disposed(by: disposeBag)
        
        viewModel.accountDetail = AccountDetail(isCashOnly: true)
        viewModel.addBankDisabled.asObservable().take(1).subscribe(onNext: { disabled in
            XCTAssert(disabled, "addBankDisabled should be true for cash only users")
        }).disposed(by: disposeBag)
    }
    
    func testEmptyStateCreditFeeLabelText() {
        if Environment.sharedInstance.opco == .bge {
            viewModel.accountDetail = AccountDetail(billingInfo: BillingInfo(residentialFee: 2, commercialFee: 5))
            let expectedStr = "A convenience fee will be applied to your payments. Residential accounts: $2.00. Business accounts: 5%"
            XCTAssert(viewModel.emptyStateCreditFeeLabelText == expectedStr, "Expected \"\(expectedStr)\", got \"\(viewModel.emptyStateCreditFeeLabelText)\"")
        } else { // ComEd/PECO
            viewModel.accountDetail = AccountDetail(billingInfo: BillingInfo(convenienceFee: 2))
            let expectedStr = "A $2.00 convenience fee will be applied\nto your payments."
            XCTAssert(viewModel.emptyStateCreditFeeLabelText == expectedStr, "Expected \"\(expectedStr)\", got \"\(viewModel.emptyStateCreditFeeLabelText)\"")
        }
    }
    
    func testFooterLabelText() {
        let expectedStr: String
        switch Environment.sharedInstance.opco {
        case .bge:
            expectedStr = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.", comment: "")
        case .comEd, .peco:
            expectedStr = NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
        XCTAssert(viewModel.footerLabelText == expectedStr, "Expected \"\(expectedStr)\", got \"\(viewModel.footerLabelText)\"")
    }
    
    
}
