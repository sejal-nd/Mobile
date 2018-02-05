//
//  WalletViewModelTests.swift
//  Mobile
//
//  Created by Marc Shilling on 2/5/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class WalletViewModelTests: XCTestCase {
    var viewModel: WalletViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        
        viewModel = WalletViewModel(walletService: MockWalletService())
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
    
    
}
