//
//  MiniWalletViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class MiniWalletViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
    let walletItems = Variable<[WalletItem]?>(nil)
    let selectedItem = Variable<WalletItem?>(nil)
    let temporaryItem = Variable<WalletItem?>(nil)
    let isFetchingWalletItems = Variable(false)
    let isError = Variable(false)
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
    func fetchWalletItems(onSuccess: @escaping () -> Void, onError: (() -> Void)? = nil) {
        isFetchingWalletItems.value = true
        isError.value = false
        walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] walletItems in
                guard let self = self else { return }
                self.isFetchingWalletItems.value = false
                self.walletItems.value = walletItems
                onSuccess()
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.isFetchingWalletItems.value = false
                    self.isError.value = true
                onError?()
            }).disposed(by: disposeBag)
    }
    
    var shouldShowTableView: Driver<Bool> {
        return Driver.combineLatest(isFetchingWalletItems.asDriver(), isError.asDriver()).map {
            return !$0 && !$1
        }
    }
    
    var shouldShowErrorLabel: Driver<Bool> {
        return Driver.combineLatest(isFetchingWalletItems.asDriver(), isError.asDriver()).map {
            return !$0 && $1
        }
    }

    var footerLabelText: String {
        return NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.", comment: "")
    }
        
}
