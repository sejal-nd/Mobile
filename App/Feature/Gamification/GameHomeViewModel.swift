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
    
    var debouncedCoinQueue = [(Date, Bool)]()
    var inFlightCoins = [(Date, Bool)]()
    let debouncedPoints = BehaviorRelay<Double?>(value: nil)
    
    var fetchDisposable: Disposable?
    
    let weeklyInsightViewModel = WeeklyInsightViewModel(gameService: ServiceFactory.createGameService(), usageService: ServiceFactory.createUsageService(useCache: false))
    let weeklyInsightEndDate = BehaviorRelay<Date?>(value: nil)
    let weeklyInsightPublishSubject = PublishSubject<Void>()
    
    let streakCount = BehaviorRelay<Int>(value: 1)
    
    var points: Double {
        get {
            return UserDefaults.standard.double(forKey: UserDefaultKeys.gamePointsLocal)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.gamePointsLocal)
        }
    }
    
    var currentTask: GameTask?
    var currentTaskIndex = -1
    
    /// Used to track when to present the gift unlock popup. Value is initially set in the fetchGameUser response. Upon earning points,
    /// gameUser will be updated and trigger an onNext in the view controller observer, which will compare the user's new number of
    /// gifts to the value being tracked here, and present the popup accordingly.
    var numGiftsUnlocked: Int?
    
    required init(accountService: AccountService, gameService: GameService) {
        self.accountService = accountService
        self.gameService = gameService
        
        debouncedPoints.asObservable()
            .filter { $0 != nil } // Ignore initial
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] points in
                guard let self = self, let accountDetail = self.accountDetail.value else { return }

                self.inFlightCoins.append(contentsOf: self.debouncedCoinQueue)
                let params = ["points": points!]
                self.gameService.updateGameUser(accountNumber: accountDetail.accountNumber, keyValues: params)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] gameUser in
                        guard let self = self else { return }
                        for tuple in self.inFlightCoins {
                           self.debouncedCoinQueue.removeAll(where: { $0 == tuple })
                        }
                        self.inFlightCoins.removeAll()
                        self.gameUser.accept(gameUser)
                    }, onError: { [weak self] _ in
                        guard let self = self else { return }
                        for tuple in self.inFlightCoins {
                            self.debouncedCoinQueue.removeAll(where: { $0 == tuple })
                            self.coreDataManager.removeCollectedCoin(accountNumber: accountDetail.accountNumber, date: tuple.0, gas: tuple.1)
                        }
                        self.inFlightCoins.removeAll()
                        self.gameUser.accept(self.gameUser.value) // To trigger point reconciliation
                        self.usageData.accept(self.usageData.value) // To trigger `layoutCoinViews`
                    }).disposed(by: self.bag)
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
        
        NewAccountService.rx.fetchAccountDetails()
            .subscribe(onNext: { [weak self] accountDetail in
                guard let self = self else { return }
                self.refreshing.accept(false)
                self.accountDetail.accept(accountDetail)
                self.fetchGameUser()
                self.fetchDailyUsage()
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
                if let points = gameUser?.points {
                    self?.numGiftsUnlocked = GiftInventory.shared.numGiftsUnlocked(forPointValue: points)
                }
                self?.streakCount.accept(UserDefaults.standard.integer(forKey: UserDefaultKeys.gameStreakCount))
                self?.gameUser.accept(gameUser)
            }).disposed(by: self.bag)
    }
    
    func fetchDailyUsage() {
        guard let accountDetail = accountDetail.value, let premiseNumber = accountDetail.premiseNumber else { return }
        
        loading.accept(true)
        error.accept(false)
        
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
            
    func updateGameUser(taskIndex: Int, advanceTaskTimer: Bool, points: Double? = nil) {
        guard let accountDetail = accountDetail.value else { return }
        var params: [String: Any] = ["taskIndex": taskIndex]
        if let p = points {
            params["points"] = p
        }
        self.gameService.updateGameUser(accountNumber: accountDetail.accountNumber, keyValues: params)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] gameUser in
                if advanceTaskTimer {
                    UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.gameLastTaskDate)
                }
                self?.gameUser.accept(gameUser)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.gameUser.accept(self.gameUser.value) // To trigger point reconciliation
            }).disposed(by: self.bag)
    }
        
    func updateGameUserAnalytic(forKey key: String) {
        guard let accountDetail = accountDetail.value else { return }
        let params = [key: true]
        _ = gameService.updateGameUser(accountNumber: accountDetail.accountNumber, keyValues: params)
            .subscribe()
    }
    
    func updateGameUserCheckInResponse(response: String, taskIndex: Int) {
        guard let accountDetail = accountDetail.value else { return }
        let params: [String: Any] = [
            "checkInHowDoYouFeelAnswer": response,
            "taskIndex": taskIndex
        ]
        gameService.updateGameUser(accountNumber: accountDetail.accountNumber, keyValues: params)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] gameUser in
                self?.gameUser.accept(gameUser)
            }).disposed(by: self.bag)
    }
    
    func updateGiftSelections() {
        guard let accountDetail = accountDetail.value else { return }
        _ = self.gameService.updateGameUserGiftSelections(accountNumber: accountDetail.accountNumber)
            .subscribe()
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
    
    var nextAvaiableTaskTimeString: String? {
        if currentTaskIndex >= GameTaskStore.shared.tasks.count {
            return nil
        }
        
        if let lastTaskDate = UserDefaults.standard.object(forKey: UserDefaultKeys.gameLastTaskDate) as? Date,
            let nextTaskDate = Calendar.current.date(byAdding: .day, value: 4, to: lastTaskDate) {
            let interval = Int(nextTaskDate.timeIntervalSinceNow)
            let days = interval / 86400
            let hours = (interval % 86400) / 3600
            let minutes = ((interval % 86400) % 3600) / 60
            
            var timeString = ""
            if days > 0 {
                timeString += "\(days) \(days == 1 ? "day" : "days")"
                if hours > 0 {
                    timeString += " and \(hours) \(hours == 1 ? "hour" : "hours")"
                }
                return "Check back in \(timeString) for your next challenge!"
            }
            if hours > 0 {
                timeString += "\(hours) \(hours == 1 ? "hour" : "hours")"
                if minutes > 0 {
                    timeString += " and \(minutes) \(minutes == 1 ? "minute" : "minutes")"
                }
                return "Check back in \(timeString) for your next challenge!"
            }
            if minutes > 0 {
                timeString += "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
                return "Check back in \(timeString) for your next challenge!"
            }
            
            return "Check back soon for your next challenge!"
        }
        
        return nil
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
