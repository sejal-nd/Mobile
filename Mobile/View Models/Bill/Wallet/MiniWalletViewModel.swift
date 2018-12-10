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
    
    var bankAccounts: [WalletItem]! {
        var banks = [WalletItem]()
        guard let walletItems = walletItems.value else { return banks }
        for item in walletItems {
            if item.bankOrCard == .bank {
                banks.append(item)
            }
        }
        return banks
    }
    
    var creditCards: [WalletItem]! {
        var cards = [WalletItem]()
        guard let walletItems = walletItems.value else { return cards }
        for item in walletItems {
            if item.bankOrCard == .card {
                cards.append(item)
            }
        }
        return cards
    }
    
    var footerLabelText: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
    }
        
}

