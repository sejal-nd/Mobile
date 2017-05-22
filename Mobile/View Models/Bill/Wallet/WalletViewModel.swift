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
    
//    lazy var shouldShowWallet: Driver<Bool> = {
//        let noWalletItems = self.walletItems.asDriver().map{ walletItems -> Bool in
//            return walletItems?.count == 0
//        }
//        return Driver.combineLatest(self.isFetchingWalletItems, noWalletItems) {
//            return !$0 && $1
//        }
//    }()
    
    var footerLabelText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.\n\nBank account verification may take up to three business days. Once activated, we will notify you via email and you may then enroll in AutoPay or begin scheduling payments for free.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("We accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
    }
}
