//
//  GameHomeViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class GameHomeViewModel {
    private let accountService: AccountService
    private let gameService: GameService
    
    let bag = DisposeBag()
    
    let loading = BehaviorRelay<Bool>(value: false)
    let error = BehaviorRelay<Error?>(value: nil)
    let accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    let usageData = BehaviorRelay<[DailyUsage]?>(value: nil)
    
    required init(accountService: AccountService, gameService: GameService) {
        self.accountService = accountService
        self.gameService = gameService
    }
    
    func fetchData() {
        loading.accept(true)
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
                        self?.error.accept(error)
                    }).disposed(by: self.bag)
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.error.accept(error)
            }).disposed(by: bag)
    }

}
