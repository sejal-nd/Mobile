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
    let fetchingWalletItemsTracker = ActivityTracker()
    let walletItems = Variable<[WalletItem]?>(nil)
    let isFetchingWalletItems: Driver<Bool>
    
    required init(walletService: WalletService) {
        self.walletService = walletService
        
        isFetchingWalletItems = fetchingWalletItemsTracker.asDriver()
        
        walletItemEvents
            .elements()
            .bind(to: walletItems)
            .disposed(by: disposeBag)
    }
    
    lazy var walletItemEvents: Observable<Event<[WalletItem]>> = self.fetchWalletItems.flatMapLatest { [unowned self] in
        self.walletService
            .fetchWalletItems()
            .trackActivity(self.fetchingWalletItemsTracker)
            .materialize()
    }.share()
    
    private(set) lazy var hasExpiredWalletItem = self.walletItemEvents.elements()
        .filter { $0.contains { $0.isExpired } }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    lazy var isError: Driver<Bool> = self.walletItemEvents.asDriver(onErrorDriveWith: .empty()).map {
        return  $0.error != nil
    }.startWith(false)
    
    lazy var shouldShowEmptyState: Driver<Bool> = {
        let noWalletItems = self.walletItems.asDriver().map{ walletItems -> Bool in
            guard let walletItems = walletItems else { return false }
            return walletItems.count == 0
        }
        return Driver.combineLatest(self.isFetchingWalletItems, noWalletItems, self.isError.asDriver()) {
            return !$0 && $1 && !$2
        }
    }()
    
    lazy var shouldShowWallet: Driver<Bool> = {
        let walletNotEmpty = self.walletItems.asDriver().map{ walletItems -> Bool in
            guard let walletItems = walletItems else { return false }
            return walletItems.count > 0
        }
        return Driver.combineLatest(self.isFetchingWalletItems, walletNotEmpty, self.isError.asDriver()) {
            return !$0 && $1 && !$2
        }
    }()
    
    var addBankDisabled: Bool {
        return self.accountDetail.isCashOnly
    }
    
    var emptyStateCreditFeeLabelText: String {
        switch Environment.shared.opco {
        case .bge:
            let feeStr = String(format: "A convenience fee will be applied to your payments. Residential accounts: %@. Business accounts: %@.",
                                accountDetail.billingInfo.residentialFee!.currencyString!, accountDetail.billingInfo.commercialFee!.percentString!)
            return NSLocalizedString(feeStr, comment: "")
        case .comEd, .peco:
            return NSLocalizedString("A " + accountDetail.billingInfo.convenienceFee!.currencyString! + " convenience fee will be applied\nto your payments.", comment: "")

        }
    }
    
    var footerLabelText: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.", comment: "")
        }
    }
}
