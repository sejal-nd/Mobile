//
//  WalletViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 5/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class WalletViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    let fetchWalletItems = PublishSubject<Void>()
    let walletItems = Variable<[WalletItem]?>(nil)
    let isFetchingWalletItems: Driver<Bool>
    
    required init(walletService: WalletService) {
        self.walletService = walletService
        
        let fetchingWalletItemsTracker = ActivityTracker()
        isFetchingWalletItems = fetchingWalletItemsTracker.asDriver()
        
        fetchWalletItems
            .flatMapLatest { _ in
                walletService
                    .fetchWalletItems()
                    .trackActivity(fetchingWalletItemsTracker)
            }
            .bind(to: walletItems)
            .addDisposableTo(disposeBag)
    }
    
    lazy var shouldShowEmptyState: Driver<Bool> = {
        let noWalletItems = self.walletItems.asDriver().map{ walletItems -> Bool in
            guard let walletItems = walletItems else { return false }
            return walletItems.count == 0
        }
        return Driver.combineLatest(self.isFetchingWalletItems, noWalletItems) {
            return !$0 && $1
        }
    }()
    
    lazy var shouldShowWallet: Driver<Bool> = {
        let walletNotEmpty = self.walletItems.asDriver().map{ walletItems -> Bool in
            guard let walletItems = walletItems else { return false }
            return walletItems.count > 0
        }
        return Driver.combineLatest(self.isFetchingWalletItems, walletNotEmpty) {
            return !$0 && $1
        }
    }()
    
    lazy var creditCardLimitReached: Driver<Bool> = self.walletItems.asDriver().map {
        if Environment.sharedInstance.opco == .bge { return false } // No limit for BGE
        
        guard let walletItems = $0 else { return false }
        var creditCount = 0
        for item in walletItems {
            if item.bankOrCard == .card {
                creditCount += 1
                if creditCount == 3 { break }
            }
        }
        return creditCount >= 3
    }
    
    lazy var bankAccountLimitReached: Driver<Bool> = self.walletItems.asDriver().map {
        if Environment.sharedInstance.opco == .bge { return false } // No limit for BGE
        
        guard let walletItems = $0 else { return false }
        var bankCount = 0
        for item in walletItems {
            if item.bankOrCard == .bank {
                bankCount += 1
                if bankCount == 3 { break }
            }
        }
        return bankCount >= 3
    }
    
    var emptyStateCreditFeeLabelText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            var feeStr = "A convenience fee will be applied to your payments. Residential accounts: " + accountDetail.billingInfo.residentialFee!.currencyString! + ".\n"
            if let commercial = accountDetail.billingInfo.commercialFee {
                feeStr += "Business accounts: \(round(commercial * 100) / 100)%"
            } else {
                feeStr += "Business accounts: 0%"
            }
            return NSLocalizedString(feeStr, comment: "")
        case .comEd, .peco:
            return NSLocalizedString("A " + accountDetail.billingInfo.convenienceFee!.currencyString! + " convenience fee will be applied\nto your payments.", comment: "")

        }
    }
    
    var footerLabelText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
    }
}
