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
    let coreDataManager = GameCoreDataManager()
    
    let bag = DisposeBag()
    
    let loading = BehaviorRelay<Bool>(value: true)
    let error = BehaviorRelay<Bool>(value: false)
    let refreshing = BehaviorRelay<Bool>(value: false)
    let accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    let gameUser = BehaviorRelay<GameUser?>(value: nil)
    let usageData = BehaviorRelay<[DailyUsage]?>(value: nil)
    
    var selectedSegmentIndex = 0
    let selectedCoinView = BehaviorRelay<DailyInsightCoinView?>(value: nil)
    
    let debouncedPoints = BehaviorRelay<Double?>(value: nil)
    
    var fetchDisposable: Disposable?
    
    let weeklyInsightViewModel = WeeklyInsightViewModel(gameService: ServiceFactory.createGameService(), usageService: ServiceFactory.createUsageService(useCache: false))
    let weeklyInsightEndDate = BehaviorRelay<Date?>(value: nil)
    let weeklyInsightPublishSubject = PublishSubject<Void>()
    
    required init(accountService: AccountService, gameService: GameService) {
        self.accountService = accountService
        self.gameService = gameService
        
        debouncedPoints.asObservable()
            .filter { $0 != nil } // Ignore initial
            .debounce(2, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] points in
                self?.updateGameUserPoints(points!)
            })
            .disposed(by: bag)
        
        self.usageData.bind(to: weeklyInsightViewModel.usageData).disposed(by: bag)
        weeklyInsightViewModel.thisWeekEndDate.drive(self.weeklyInsightEndDate).disposed(by: bag)
    }
    
    deinit {
        fetchDisposable?.dispose()
    }
    
    func fetchData(pullToRefresh: Bool = false) {
        if pullToRefresh {
            refreshing.accept(true)
        } else {
            loading.accept(true)
            error.accept(false)
        }
        
        accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
            .subscribe(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                
                self.accountDetail.accept(accountDetail)
                self.fetchGameUser()
                self.fetchDailyUsage(pullToRefresh)
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.refreshing.accept(false)
                self?.error.accept(true)
            }).disposed(by: bag)
    }
    
    func fetchGameUser() {
        guard let accountDetail = accountDetail.value else { return }
        self.gameService.fetchGameUser(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] gameUser in
                self?.gameUser.accept(gameUser)
            }).disposed(by: self.bag)
    }
    
    func fetchDailyUsage(_ pullToRefresh: Bool = false) {
        guard let accountDetail = accountDetail.value, let premiseNumber = accountDetail.premiseNumber else { return }
        
        if !pullToRefresh {
            loading.accept(true)
            error.accept(false)
        }
        
        let fetchGas = accountDetail.serviceType?.uppercased() == "GAS" || selectedSegmentIndex == 1
        
        fetchDisposable?.dispose()
        fetchDisposable = self.gameService.fetchDailyUsage(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, gas: fetchGas)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] usageArray in
                self?.loading.accept(false)
                self?.refreshing.accept(false)
                self?.error.accept(false)
                self?.weeklyInsightPublishSubject.onNext(()) // So that the combineLatest fires initially
                self?.usageData.accept(usageArray)
            }, onError: { [weak self] error in
                self?.loading.accept(false)
                self?.refreshing.accept(false)
                self?.error.accept(true)
            })
    }
    
    func updateGameUserPoints(_ points: Double) {
        guard let accountDetail = accountDetail.value else { return }
        let params = ["points": points]
        self.gameService.updateGameUser(accountNumber: accountDetail.accountNumber, keyValues: params)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] gameUser in
                self?.gameUser.accept(gameUser)
            }).disposed(by: self.bag)
    }
    
    func updateGameUserTaskIndex(_ index: Int) {
        guard let accountDetail = accountDetail.value else { return }
        let params = ["taskIndex": index]
        self.gameService.updateGameUser(accountNumber: accountDetail.accountNumber, keyValues: params)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] gameUser in
                UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.gameLastTaskDate)
                self?.gameUser.accept(gameUser)
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
    
    private(set) lazy var shouldShowWeeklyInsightUnreadIndicator: Driver<Bool> =
        Driver.combineLatest(self.weeklyInsightViewModel.usageDataIsValid,
                             self.weeklyInsightEndDate.asDriver(),
                             self.weeklyInsightPublishSubject.asDriver(onErrorJustReturn: ()))
            .map { [weak self] valid, date, _ in
                guard let self = self,
                    let accountNumber = self.accountDetail.value?.accountNumber,
                    valid,
                    let endDate = date else { return false }
                return self.coreDataManager.getWeeklyInsight(accountNumber: accountNumber, endDate: endDate) == nil
            }
}
