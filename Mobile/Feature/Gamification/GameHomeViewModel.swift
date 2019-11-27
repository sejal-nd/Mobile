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
    
    var selectedSegmentIndex = 0
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
                guard let self = self else { return }
                
                self.accountDetail.accept(accountDetail)
                self.fetchDailyUsage()
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.error.accept(true)
            }).disposed(by: bag)
    }
    
    func fetchDailyUsage() {
        guard let accountDetail = accountDetail.value, let premiseNumber = accountDetail.premiseNumber else { return }
        loading.accept(true)
        error.accept(false)
        let fetchGas = selectedSegmentIndex == 1
        self.gameService.fetchDailyUsage(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, gas: fetchGas)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] usageArray in
                self?.loading.accept(false)
                self?.usageData.accept(usageArray)
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.error.accept(true)
            }).disposed(by: self.bag)
    }
        
    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.loading.asDriver(), self.error.asDriver(), self.usageData.asDriver()) {
            return !$0 && !$1 && $2 != nil
        }
    
    private(set) lazy var shouldShowError: Driver<Bool> =
        Driver.combineLatest(self.loading.asDriver(), self.error.asDriver()) {
            return !$0 && $1
        }
    
    private(set) lazy var shouldShowSegmentedControl: Driver<Bool> = self.accountDetail.asDriver().map {
        guard let accountDetail = $0 else { return false }
        return accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC"
    }
    
    private(set) lazy var bubbleLabelText: Driver<String?> = self.selectedCoinView.asDriver().map {
        $0?.lastWeekComparisonString
    }
        
    
}
