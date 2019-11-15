//
//  GameHomeViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class GameHomeViewModel {
    private let accountService: AccountService
    private let gameService: GameService
    
    let bag = DisposeBag()
    
    let loading = BehaviorRelay<Bool>(value: true)
    let error = BehaviorRelay<Bool>(value: false)
    let accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    let usageData = BehaviorRelay<[DailyUsage]?>(value: nil)
    let selectedCoinView = BehaviorRelay<DailyInsightCoinView?>(value: nil)
    
    required init(accountService: AccountService, gameService: GameService) {
        self.accountService = accountService
        self.gameService = gameService
    }
    
    func fetchData() {
        loading.accept(true)
        error.accept(false)
        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let self = self, let premiseNumber = accountDetail.premiseNumber else { return }
                
                self.accountDetail.accept(accountDetail)
                self.gameService.fetchDailyUsage(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, gas: false)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] usageArray in
                        self?.loading.accept(false)
                        self?.usageData.accept(usageArray)
                    }, onError: { [weak self] error in
                        self?.loading.accept(false)
                        self?.error.accept(true)
                    }).disposed(by: self.bag)
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.error.accept(true)
            }).disposed(by: bag)
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.loading.asDriver(), self.error.asDriver(), self.usageData.asDriver()) {
            return !$0 && !$1 && $2 != nil
        }
    
    private(set) lazy var bubbleLabelText: Driver<String?> = self.selectedCoinView.asDriver().map {
        if let usage = $0?.usage {
            var string = String.localizedStringWithFormat("You used %@ %@.", usage.amount.twoDecimalString, usage.unit)
            if let lastWeekUsage = $0?.lastWeekUsage {
                string += String.localizedStringWithFormat(" You used %@ %@ last week.", lastWeekUsage.amount.twoDecimalString, lastWeekUsage.unit)
            }
            return string
        } else {
            return NSLocalizedString("Data not yet available. It generally takes 24 to 48 hours to appear. Check back later!", comment: "")
        }
    }
        
    
}
