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
    
    func fetchWalletItems(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        isFetchingWalletItems.value = true
        isError.value = false
        walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItems in
                self.isFetchingWalletItems.value = false
                self.walletItems.value = walletItems
                onSuccess()
            }, onError: { err in
                self.isFetchingWalletItems.value = false
                self.isError.value = true
                onError(err.localizedDescription)
            }).addDisposableTo(disposeBag)
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
    
    var creditCardFeeString: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("A $1.50 convenience fee will be applied.", comment: "")
        case .comEd:
            return NSLocalizedString("A $2.50 convenience fee will be applied.", comment: "")
        case .peco:
            return NSLocalizedString("A $2.35 convenience fee will be applied.", comment: "")
        }
    }
    
    var bankAccounts: [WalletItem]! {
        var banks = [WalletItem]()
        guard let walletItems = self.walletItems.value else { return banks }
        for item in walletItems {
            if item.bankOrCard == .bank {
                banks.append(item)
            }
        }
        return banks
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
    
    var creditCards: [WalletItem]! {
        var cards = [WalletItem]()
        guard let walletItems = self.walletItems.value else { return cards }
        for item in walletItems {
            if item.bankOrCard == .card {
                cards.append(item)
            }
        }
        return cards
    }
    
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
    
}

