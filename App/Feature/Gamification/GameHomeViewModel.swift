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
    let coreDataManager = GameCoreDataManager()
    
    let bag = DisposeBag()
    
    let loading = BehaviorRelay<Bool>(value: true)
    let error = BehaviorRelay<Bool>(value: false)
    let refreshing = BehaviorRelay<Bool>(value: false)
    let accountDetail = BehaviorRelay<AccountDetail?>(value: nil)
    let gameUser = BehaviorRelay<GameUser?>(value: nil)
    let usageData = BehaviorRelay<DailyUsageData?>(value: nil)
    
    var selectedSegmentIndex = 0
    let selectedCoinView = BehaviorRelay<DailyInsightCoinView?>(value: nil)
    
    var debouncedCoinQueue = [(Date, Bool)]()
    var inFlightCoins = [(Date, Bool)]()
    let debouncedPoints = BehaviorRelay<Double?>(value: nil)
    
    var fetchDisposable: Disposable?
    
    let weeklyInsightViewModel = WeeklyInsightViewModel()
    let weeklyInsightEndDate = BehaviorRelay<Date?>(value: nil)
    let weeklyInsightPublishSubject = PublishSubject<Void>()
    
    let streakCount = BehaviorRelay<Int>(value: 1)
    
    // seconds between each task
    lazy var taskInterval: Int = {
        if Environment.shared.environmentName == .prod {
            return 60 * 60 * 24 * 4 // 4 days
        } else {
            return 10 // 10 seconds
        }
    }()
    
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
    
    required init() {
        
        debouncedPoints.asObservable()
            .filter { $0 != nil } // Ignore initial
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] points in
                guard let self = self, let accountDetail = self.accountDetail.value else { return }

                self.inFlightCoins.append(contentsOf: self.debouncedCoinQueue)
                
                
                var gameUserRequest = GameUserRequest()
                if let points = points {
                    gameUserRequest.points = String(points)
                }
                
                GameService.updateGameUser(accountNumber: accountDetail.accountNumber, request: gameUserRequest) { [weak self] result in
                    switch result {
                    case .success(let gameUser):
                        guard let self = self else { return }
                        for tuple in self.inFlightCoins {
                            self.debouncedCoinQueue.removeAll(where: { $0 == tuple })
                        }
                        self.inFlightCoins.removeAll()
                        self.gameUser.accept(gameUser)
                    case .failure:
                        guard let self = self else { return }
                        for tuple in self.inFlightCoins {
                            self.debouncedCoinQueue.removeAll(where: { $0 == tuple })
                            self.coreDataManager.removeCollectedCoin(accountNumber: accountDetail.accountNumber, date: tuple.0, gas: tuple.1)
                        }
                        self.inFlightCoins.removeAll()
                        self.gameUser.accept(self.gameUser.value) // To trigger point reconciliation
                        self.usageData.accept(self.usageData.value) // To trigger `layoutCoinViews`
                    }
                }
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
        
        AccountService.fetchAccountDetails { [weak self] result in
            switch result {
            case .success(let accountDetail):
                self?.refreshing.accept(false)
                self?.accountDetail.accept(accountDetail)
                self?.fetchGameUser()
                self?.fetchDailyUsage()
            case .failure:
                self?.loading.accept(false)
                self?.refreshing.accept(false)
                self?.error.accept(true)
            }
        }
    }
    
    func fetchGameUser() {
        guard let accountDetail = accountDetail.value else { return }
        GameService.fetchGameUser(accountNumber: accountDetail.accountNumber) { [weak self] result in
            switch result {
            case .success(let gameUser):
                if let points = gameUser?.points {
                    self?.numGiftsUnlocked = GiftInventory.shared.numGiftsUnlocked(forPointValue: points)
                }
                self?.streakCount.accept(UserDefaults.standard.integer(forKey: UserDefaultKeys.gameStreakCount))
                self?.gameUser.accept(gameUser)
            case .failure:
                break
            }
        }
    }
    
    func fetchDailyUsage() {
        guard let accountDetail = accountDetail.value, let premiseNumber = accountDetail.premiseNumber else { return }
        
        loading.accept(true)
        error.accept(false)
        
        let fetchGas = accountDetail.serviceType?.uppercased() == "GAS" || selectedSegmentIndex == 1
        
        fetchDisposable?.dispose()
        fetchDisposable = GameService.rx.fetchDailyUsage(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, gas: fetchGas)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] usageData in
            self?.loading.accept(false)
            self?.refreshing.accept(false)
            self?.error.accept(false)
            self?.weeklyInsightPublishSubject.onNext(()) // So that the combineLatest fires initially
            self?.usageData.accept(usageData)
        }, onError: { [weak self] error in
            self?.loading.accept(false)
            self?.refreshing.accept(false)
            self?.error.accept(true)
        })
    }
            
    func updateGameUser(taskIndex: Int, advanceTaskTimer: Bool, points: Double? = nil) {
        guard let accountDetail = accountDetail.value else { return }
        
        var gameUserRequest = GameUserRequest(taskIndex: String(taskIndex))
        if let points = points {
            gameUserRequest.points = String(points)
        }
        GameService.updateGameUser(accountNumber: accountDetail.accountNumber, request: gameUserRequest) { [weak self] result in
            switch result {
            case .success(let gameUser):
                if advanceTaskTimer {
                    UserDefaults.standard.set(Date.now, forKey: UserDefaultKeys.gameLastTaskDate)
                }
                self?.gameUser.accept(gameUser)
            case .failure:
                guard let self = self else { return }
                self.gameUser.accept(self.gameUser.value) // To trigger point reconciliation
            }
        }
    }
        
    func updateGameUserAnalytic(pilotEBillEnrollment: String? = nil, pilotHomeProfileCompletion: String? = nil) {
        guard let accountDetail = accountDetail.value else { return }
        var gameUserRequest = GameUserRequest()
        if let pilotEBillEnrollment = pilotEBillEnrollment {
            gameUserRequest.pilotEBillEnrollment = pilotEBillEnrollment
        }
        
        if let pilotHomeProfileCompletion = pilotHomeProfileCompletion {
            gameUserRequest.pilotHomeProfileCompletion = pilotHomeProfileCompletion
        }
        
        _ = GameService.rx.updateGameUser(accountNumber: accountDetail.accountNumber, request: gameUserRequest)
            .subscribe()
    }
    
    func updateGameUserCheckInResponse(response: String, taskIndex: Int) {
        guard let accountDetail = accountDetail.value else { return }
        let gameUserRequest = GameUserRequest(taskIndex: String(taskIndex),
                                              checkInHowDoYouFeelAnswer: response)
        GameService.updateGameUser(accountNumber: accountDetail.accountNumber, request: gameUserRequest) { [weak self] result in
            switch result {
            case .success(let gameUser):
                self?.gameUser.accept(gameUser)
            case .failure:
                break
            }
        }
    }
    
    func updateGiftSelections() {
        guard let accountDetail = accountDetail.value else { return }
        _ = GameService.rx.updateGameUserGiftSelections(accountNumber: accountDetail.accountNumber)
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
           let nextTaskDate = Calendar.current.date(byAdding: .second, value: self.taskInterval, to: lastTaskDate) {
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
                var weeklyInsightAvailable = self.coreDataManager.getWeeklyInsight(accountNumber: accountNumber, endDate: endDate) == nil
                return weeklyInsightAvailable
            }
    
    func hasDailyInsightAvailable() -> Observable<Bool> {
        return self.usageData.asObservable().map {
            if let dailyUsageData = $0 {
                var insightAvailable = false
                var date = Calendar.current.startOfDay(for: Date.now) // Based on user's timezone so their current "today" is always displayed
                let startDate = Calendar.current.date(byAdding: .day, value: -6, to: date)!
                
                while date > startDate, !insightAvailable {
                    if let match = dailyUsageData.dailyUsage.filter({ Calendar.gmt.isDate($0.date, inSameDayAs: date) }).first {
                        let accountNumber = self.accountDetail.value!.accountNumber
                        let canCollect = self.coreDataManager.getCollectedCoin(accountNumber: accountNumber, date: match.date, gas: self.selectedSegmentIndex == 1) == nil
                        
                        insightAvailable = canCollect || insightAvailable
                    }
                    date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                }
                                
                return insightAvailable
            }
            else {
                return false
            }
        }
    }
    
    func hasInsightsAvailable() -> Driver<Bool> {
        return Driver.combineLatest(shouldShowWeeklyInsightUnreadIndicator, hasDailyInsightAvailable().asDriver(onErrorJustReturn: false)).map { $0 || $1 }
    }
    
    func taskIndicatorText(for taskType: GameTaskType) -> String {
        var taskIndicatorText: String
        switch taskType {
        case .tip:
            taskIndicatorText = NSLocalizedString("New Tip Available!", comment: "")
        case .quiz:
            taskIndicatorText = NSLocalizedString("New Quiz Available!", comment: "")
        default:
            taskIndicatorText = NSLocalizedString("New Task Available!", comment: "")
        }
        
        return taskIndicatorText
    }
    
    func checkForAvailableTask() -> GameTask? {
        guard let gameUser = gameUser.value,
              let accountDetail = accountDetail.value else { return nil}
        #warning("Gamification Testing Only! Uncomment for Release!")
        if let lastTaskDate = UserDefaults.standard.object(forKey: UserDefaultKeys.gameLastTaskDate) as? Date {
            let secondsSinceLastTask = abs(lastTaskDate.interval(ofComponent: .second, fromDate: Date.now, usingCalendar: Calendar.current))
            if secondsSinceLastTask < taskInterval {
                return nil
            }
        }
        
        while true {
            if let task = GameTaskStore.shared.tasks.get(at: currentTaskIndex) {
                if shouldFilterOutTask(task: task, gameUser: gameUser, accountDetail: accountDetail) {
                    self.currentTaskIndex += 1
                } else {
                    return task
                }
            } else {
                break
            }
        }
        
        return nil
    }
    
    private func shouldFilterOutTask(task: GameTask, gameUser: GameUser, accountDetail: AccountDetail) -> Bool {
        if let survey = task.survey {
            if survey.surveyNumber == 1 && UserDefaults.standard.bool(forKey: UserDefaultKeys.gameSurvey1Complete) {
                return true
            }
            if survey.surveyNumber == 2 && UserDefaults.standard.bool(forKey: UserDefaultKeys.gameSurvey2Complete) {
                return true
            }
        }
        
        // eBill Enroll Task: Should filter out if already enrolled, or ineligible for enrollment
        if task.type == .eBill && (accountDetail.isEBillEnrollment || accountDetail.eBillEnrollStatus != .canEnroll) {
            return true
        }
                
        // Tip/Quiz will either be "RENT", "OWN" or "RENT/OWN". If user's rent/own onboarding response
        // is not contained in that string, task should be filtered out
        if let gameUserRentOrOwn = gameUser.onboardingRentOrOwnAnswer?.uppercased() {
            if let tip = task.tip, !tip.rentOrOwn.uppercased().contains(gameUserRentOrOwn) {
                return true
            }
            if let quiz = task.quiz, !quiz.rentOrOwn.uppercased().contains(gameUserRentOrOwn) {
                return true
            }
        }
        
        // Season will either be "WINTER", "SUMMER", or nil. Winter tips should only be displayed
        // in October - March, while Summer tips should only be displayed in April - September
        var taskSeason: String?
        if let tip = task.tip, let tipSeason = tip.season?.uppercased() {
            taskSeason = tipSeason
        } else if let quiz = task.quiz, let quizSeason = quiz.season?.uppercased() {
            taskSeason = quizSeason
        }
        if let season = taskSeason, let month = Calendar.current.dateComponents([.month], from: Date.now).month {
            if season == "SUMMER" && month >= 10 && month <= 3 { // October - March, filter out summer tips
                return true
            }
            if season == "WINTER" && month >= 4 && month <= 9 { // April - September, filter out winter tips
                return true
            }
        }
        
        return false
    }
}
