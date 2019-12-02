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
    
    var selectedSegmentIndex = 0
    
    var shortDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        return dateFormatter
    }
    
    required init(gameService: GameService, usageService: UsageService) {
        self.gameService = gameService
        self.usageService = usageService
        
    }
    
    func fetchData() {
        loading.accept(true)
        error.accept(false)
        Observable.zip([fetchDailyUsageData(), fetchBillForecast()])
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
        let fetchGas = accountDetail.serviceType?.uppercased() == "GAS" || selectedSegmentIndex == 1
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
    
    var shouldShowSegmentedControl: Bool {
        return accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC"
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
            print("THIS WEEK")
            print(filtered)
            return filtered
        }
        
        return nil
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
            print("LAST WEEK")
            print(filtered)
            return filtered
        }
        
        return nil
    }
    
    private lazy var usageDataIsValid: Driver<Bool> = self.usageData.asDriver().map {
        guard let usageData = $0 else { return false }
        
        
        return true
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> =
        Driver.combineLatest(self.loading.asDriver(), self.error.asDriver(), self.usageDataIsValid)
            .map { !$0 && !$1 && $2}
    
    private(set) lazy var thisWeekDateLabelText: Driver<String?> = self.thisWeekData.map { [weak self] in
        guard let self = self, let data = $0 else { return nil }
        
        if let start = data.first?.date, let end = data.last?.date {
            return "\(self.shortDateFormatter.string(from: start)) - \(self.shortDateFormatter.string(from: end))"
        }
        
        return nil
    }
    
    private(set) lazy var lastWeekDateLabelText: Driver<String?> = self.lastWeekData.map { [weak self] in
        guard let self = self, let data = $0 else { return nil }
        
        if let start = data.first?.date, let end = data.last?.date {
            return "\(self.shortDateFormatter.string(from: start)) - \(self.shortDateFormatter.string(from: end))"
        }
        
        return nil
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

