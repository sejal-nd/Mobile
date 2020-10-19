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
        
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    let fetchWalletItems = PublishSubject<Void>()
    let fetchingWalletItemsTracker = ActivityTracker()
    let walletItems = BehaviorRelay<[WalletItem]?>(value: nil)
    let isFetchingWalletItems: Driver<Bool>
    
    required init() {
        isFetchingWalletItems = fetchingWalletItemsTracker.asDriver()
        
        walletItemEvents
            .elements()
            .bind(to: walletItems)
            .disposed(by: disposeBag)
    }
    
    lazy var walletItemEvents: Observable<Event<[WalletItem]>> = self.fetchWalletItems.flatMapLatest { [unowned self] in
        WalletService.rx
            .fetchWalletItems()
            .trackActivity(self.fetchingWalletItemsTracker)
            .materialize()
    }.share()
    
    func deleteWalletItem(walletItem: WalletItem, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        WalletService.deletePaymentMethod(walletItem: walletItem) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
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

    var emptyFooterLabelString: String {
        return Environment.shared.opco.isPHI ? NSLocalizedString("We accept: VISA, MasterCard, Discover and American Express Credit Cards or Check Cards.\n\nPayment methods saved to My Wallet are stored by Paymentus Corporation.", comment: "") : NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.\n\nPayment methods saved to My Wallet are stored by Paymentus Corporation.", comment: "")
    }
    
    var footerLabelString: String {
        return Environment.shared.opco.isPHI ? NSLocalizedString("We accept: VISA, MasterCard, Discover and American Express Credit Cards or Check Cards.", comment: "") : NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.", comment: "")
    }
}
