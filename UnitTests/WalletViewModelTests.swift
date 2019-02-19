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
    
    func testAddBankDisabled() {
        viewModel.walletItems.value = []
        viewModel.accountDetail = AccountDetail.default
        XCTAssertFalse(viewModel.addBankDisabled, "addBankDisabled should be false for non-cash only users")

        viewModel.accountDetail = AccountDetail.fromMockJson(forKey: .cashOnly)
        XCTAssert(viewModel.addBankDisabled, "addBankDisabled should be true for cash only users")
    }
        
    func testFooterLabelText() {
        XCTAssertEqual(viewModel.footerLabelText, NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.\n\nPayment methods saved to My Wallet are stored by Paymentus Corporation.", comment: ""))
    }
    
}
