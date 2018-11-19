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
        AccountsStore.shared.currentAccount = Account.from(["accountNumber": "1234567890", "address": "573 Elm Street"])!
        
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
    
    func testAddBankDisabled() {
        viewModel.walletItems.value = []
        viewModel.accountDetail = AccountDetail()
        XCTAssertFalse(viewModel.addBankDisabled, "addBankDisabled should be false for non-cash only users")

        viewModel.accountDetail = AccountDetail(isCashOnly: true)
        XCTAssert(viewModel.addBankDisabled, "addBankDisabled should be true for cash only users")
    }
    
    func testEmptyStateCreditFeeLabelText() {
        if Environment.shared.opco == .bge {
            viewModel.accountDetail = AccountDetail(billingInfo: BillingInfo(residentialFee: 2, commercialFee: 5))
            let expectedStr = "A convenience fee will be applied to your payments. Residential accounts: $2.00. Business accounts: 5%."
            XCTAssert(viewModel.emptyStateCreditFeeLabelText == expectedStr, "Expected \"\(expectedStr)\", got \"\(viewModel.emptyStateCreditFeeLabelText)\"")
        } else { // ComEd/PECO
            viewModel.accountDetail = AccountDetail(billingInfo: BillingInfo(convenienceFee: 2))
            let expectedStr = "A $2.00 convenience fee will be applied\nto your payments."
            XCTAssert(viewModel.emptyStateCreditFeeLabelText == expectedStr, "Expected \"\(expectedStr)\", got \"\(viewModel.emptyStateCreditFeeLabelText)\"")
        }
    }
    
    func testFooterLabelText() {
        let expectedStr: String
        switch Environment.shared.opco {
        case .bge:
            expectedStr = NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.", comment: "")
        case .comEd, .peco:
            expectedStr = NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.", comment: "")
        }
        XCTAssert(viewModel.footerLabelText == expectedStr, "Expected \"\(expectedStr)\", got \"\(viewModel.footerLabelText)\"")
    }
    
    
}
