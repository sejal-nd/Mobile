//
//  BillHomeCard.swift
//  Mobile
//
//  Created by Sam Francis on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BillHomeCardViewModel {
    
    let bag = DisposeBag()
    
    private let accountService: AccountService
    private let walletService: WalletService
    
    private let accountDetail = Variable<AccountDetail?>(nil)
    private let walletItem = Variable<WalletItem?>(nil)
    
    let account: Variable<Account>
    
    private let loadingTracker = ActivityTracker()
    
    init(withAccount account: Account, accountService: AccountService, walletService: WalletService) {
        self.account = Variable(account)
        self.accountService = accountService
        self.walletService = walletService
        
        self.account.asObservable()
            .flatMapLatest(fetchAccountDetails)
            .do(onNext: { [weak self] accountDetail in
                self?.accountDetail.value = accountDetail
            })
            .flatMapLatest(fetchWalletItem)
            .bind(to: walletItem)
            .addDisposableTo(bag)
    }
    
    private func fetchAccountDetails(forAccount account: Account) -> Observable<AccountDetail> {
        return accountService.fetchAccountDetail(account: account)
            .trackActivity(loadingTracker)
    }
    
    private func fetchWalletItem(forAccountDetail accountDetail: AccountDetail) -> Observable<WalletItem> {
        return walletService.fetchDefaultWalletItem(accountDetail: accountDetail)
            .trackActivity(loadingTracker)
    }
    
    
    private(set) lazy var isLoading: Driver<Bool> = self.loadingTracker.asDriver()
    
    private(set) lazy var errorOccurred: Driver<Bool> = Driver.combineLatest(self.isLoading,
                                                                             self.accountDetail.asDriver(),
                                                                             self.walletItem.asDriver())
    { !$0 && $1 == nil && $2 == nil }
    
    
    
    
    
}
