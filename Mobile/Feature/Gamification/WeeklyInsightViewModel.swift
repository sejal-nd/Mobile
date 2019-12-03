//
//  WeeklyInsightViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 12/2/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class WeeklyInsightViewModel {
    private let gameService: GameService
    private let usageService: UsageService
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail! // Passed from GameHomeViewController
    
    let loading = BehaviorRelay<Bool>(value: false)
    let error = BehaviorRelay<Bool>(value: false)

    let usageData = BehaviorRelay<[DailyUsage]?>(value: nil)
    let billForecast = BehaviorRelay<BillForecastResult?>(value: nil)
    
    let selectedSegmentIndex = BehaviorRelay<Int>(value: 0)
        
    required init(gameService: GameService, usageService: UsageService) {
        self.gameService = gameService
        self.usageService = usageService
    }
    
    func fetchData() {
        var observables = [fetchDailyUsageData()]
        if billForecast.value == nil {
            observables.append(fetchBillForecast())
        }
        
        loading.accept(true)
        error.accept(false)
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.loading.accept(false)
                self.error.accept(false)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.loading.accept(false)
                self.error.accept(true)
            })
            .disposed(by: bag)
    }
    
    func fetchDailyUsageData() -> Observable<Void> {
        let fetchGas = accountDetail.serviceType?.uppercased() == "GAS" || selectedSegmentIndex.value == 1
        return gameService.fetchDailyUsage(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!, gas: fetchGas)
            .do(onNext: { [weak self] usageData in
                self?.usageData.accept(usageData)
            })
            .mapTo(())
    }
    
    func fetchBillForecast() -> Observable<Void> {
        return usageService.fetchBillForecast(accountNumber: accountDetail.accountNumber, premiseNumber: accountDetail.premiseNumber!)
            .do(onNext: { [weak self] billForecast in
                self?.billForecast.accept(billForecast)
            })
            .mapTo(())
            .catchErrorJustReturn(())
    }
        
    private lazy var thisWeekData: Driver<[DailyUsage]?> = self.usageData.asDriver().map { [weak self] in
        guard let self = self, let usageData = $0, let mostRecentDataDate = usageData.first?.date else { return nil }
        
        let now = Calendar.opCo.startOfDay(for: Date())
        let mostRecentSaturday = now.previousSaturday()
        
        var endDate: Date?
        if mostRecentDataDate >= mostRecentSaturday {
            endDate = mostRecentSaturday
        } else if let weekBefore = Calendar.opCo.date(byAdding: .day, value: -7, to: mostRecentSaturday), mostRecentDataDate >= weekBefore {
            endDate = weekBefore
        }
        
        if endDate == nil { return nil }
        
        if let start = Calendar.opCo.date(byAdding: .day, value: -6, to: endDate!) {
            var filtered = usageData.filter {
                $0.date >= start && $0.date <= endDate!
            }
            filtered.reverse() // Oldest to most recent
            return filtered
        }
        
        return nil
    }
    
    private lazy var thisWeekUsageTotal: Driver<Double?> = self.thisWeekData.map {
        guard let thisWeekData = $0 else { return nil }
        let total = thisWeekData.reduce(0) { $0 + $1.amount }
        return total
    }
    
    private lazy var lastWeekData: Driver<[DailyUsage]?> = self.usageData.asDriver().map { [weak self] in
        guard let self = self, let usageData = $0, let mostRecentDataDate = usageData.first?.date else { return nil }
        
        let now = Calendar.opCo.startOfDay(for: Date())
        let mostRecentSaturday = now.previousSaturday()
        
        var currentWeekEndDate: Date?
        if mostRecentDataDate >= mostRecentSaturday {
            currentWeekEndDate = mostRecentSaturday
        } else if let weekBefore = Calendar.opCo.date(byAdding: .day, value: -7, to: mostRecentSaturday), mostRecentDataDate >= weekBefore {
            currentWeekEndDate = weekBefore
        }
        
        if currentWeekEndDate == nil { return nil }
        
        if let end = Calendar.opCo.date(byAdding: .day, value: -7, to: currentWeekEndDate!),
            let start = Calendar.opCo.date(byAdding: .day, value: -6, to: end) {
            var filtered = usageData.filter {
                $0.date >= start && $0.date <= end
            }
            filtered.reverse()  // Oldest to most recent
            return filtered
        }
        
        return nil
    }
    
    private lazy var lastWeekUsageTotal: Driver<Double?> = self.lastWeekData.map {
        guard let lastWeekData = $0 else { return nil }
        let total = lastWeekData.reduce(0) { $0 + $1.amount }
        return total
    }
    
    private lazy var usageDataIsValid: Driver<Bool> = self.usageData.asDriver().map {
        guard let usageData = $0 else { return false }
        
        
        return true
    }
    
    var shouldShowSegmentedControl: Bool {
        return accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC"
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.loading.asDriver(), self.error.asDriver(), self.usageDataIsValid)
            .map { !$0 && !$1 && $2}
    
    private(set) lazy var thisWeekDateLabelText: Driver<String?> = self.thisWeekData.map {
        guard let data = $0 else { return nil }
        if let start = data.first?.date, let end = data.last?.date {
            return "\(start.gameShortString) - \(end.gameShortString)"
        }
        return nil
    }
    
    private(set) lazy var thisWeekBarWidth: Driver<CGFloat> =
        Driver.combineLatest(self.thisWeekUsageTotal, self.lastWeekUsageTotal).map {
            guard let thisWeek = $0, let lastWeek = $1 else { return 0 }
            if thisWeek >= lastWeek {
                return 250
            } else {
                let percentage = CGFloat(thisWeek / lastWeek)
                return percentage * 250
            }
        }
    
    private(set) lazy var lastWeekDateLabelText: Driver<String?> = self.lastWeekData.map { [weak self] in
        guard let self = self, let data = $0 else { return nil }
        if let start = data.first?.date, let end = data.last?.date {
            return "\(start.gameShortString) - \(end.gameShortString)"
        }
        return nil
    }
    
    private(set) lazy var lastWeekBarWidth: Driver<CGFloat> =
        Driver.combineLatest(self.thisWeekUsageTotal, self.lastWeekUsageTotal).map {
            guard let thisWeek = $0, let lastWeek = $1 else { return 0 }
            if lastWeek >= thisWeek {
                return 250
            } else {
                let percentage = CGFloat(lastWeek / thisWeek)
                return percentage * 250
            }
        }
    
    private(set) lazy var comparisonLabelText: Driver<String?> =
        Driver.combineLatest(self.thisWeekUsageTotal, self.lastWeekUsageTotal).map {
            guard let thisWeek = $0, let lastWeek = $1 else { return nil }
            
            let decreaseValue = thisWeek - lastWeek
            var percentChange: Int
            if thisWeek == 0 && lastWeek == 0 {
                percentChange = 0
            } else if thisWeek == 0 {
                percentChange = -100
            } else if lastWeek == 0 {
                percentChange = 100
            } else {
                percentChange = Int((decreaseValue / thisWeek) * 100)
            }
            
            if percentChange == 0 {
                return NSLocalizedString("You used about the same amount of energy as the previous week.", comment: "")
            } else if percentChange < 0 {
                return String.localizedStringWithFormat("You used %d%% less energy than the previous week.", abs(percentChange))
            } else {
                return String.localizedStringWithFormat("You used %d%% more energy than the previous week.", percentChange)
            }
        }
    
    private(set) lazy var mostEnergyLabelText: Driver<String?> = self.thisWeekData.map { [weak self] in
        guard let thisWeekData = $0 else { return nil }
        if let maxDataPoint = thisWeekData.max(by: { $0.amount < $1.amount }) {
            return String.localizedStringWithFormat("You used the most energy on %@.", maxDataPoint.date.gameLongString)
        }
        return nil
    }
    
    private(set) lazy var leastEnergyLabelText: Driver<String?> = self.thisWeekData.map { [weak self] in
        guard let thisWeekData = $0 else { return nil }
        if let minDataPoint = thisWeekData.min(by: { $0.amount < $1.amount }) {
            return String.localizedStringWithFormat("You used the least energy on %@.", minDataPoint.date.gameLongString)
        }
        return nil
    }
    
    private(set) lazy var billProjectionLabelText: Driver<String?> =
        Driver.combineLatest(self.billForecast.asDriver(), self.selectedSegmentIndex.asDriver()).map { [weak self] in
            let notAvailableLabel = NSLocalizedString("Projection not available. Data becomes available once you are more than 7 days into the billing cycle.", comment: "")
            guard let self = self, let billForecast = $0.0 else { return notAvailableLabel }
            
            let isGas = self.accountDetail.serviceType?.uppercased() == "GAS" || $0.1 == 1
            if self.accountDetail.isModeledForOpower {
                if let forecast = isGas ? billForecast.gas : billForecast.electric,
                    let projected = forecast.projectedCost,
                    let toDate = forecast.toDateCost {
                    return String.localizedStringWithFormat("Your bill is projected to be %@. You've spent about %@ so far this bill period.", projected.currencyString, toDate.currencyString)
                }
            } else {
                if let forecast = isGas ? billForecast.gas : billForecast.electric,
                    let projected = forecast.projectedUsage,
                    let toDate = forecast.toDateUsage {
                    return String.localizedStringWithFormat("You are projected to use around %d %@. You've used about %d %@ so far this bill period.",
                                                            Int(projected),
                                                            forecast.meterUnit,
                                                            Int(toDate),
                                                            forecast.meterUnit)
                }
            }
            return notAvailableLabel
        }

}

fileprivate extension Date {
    func previousSaturday() -> Date {
        if Calendar.current.component(.weekday, from: self) == 7 { // Callee was a Saturday
            return self
        }
        
        var nextDateComponent = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        nextDateComponent.weekday = 7
        
        let previousSaturday = Calendar.current.nextDate(after: self,
                                                         matching: nextDateComponent,
                                                         matchingPolicy: .nextTime,
                                                         direction: .backward)
        return previousSaturday!
    }
        
}

