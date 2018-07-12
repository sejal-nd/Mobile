//
//  SmartThermostatScheduleViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartThermostatScheduleViewModel {
    private let peakRewardsService: PeakRewardsService
    private let accountDetail: AccountDetail
    
    private let schedule: SmartThermostatDeviceSchedule
    private let device: SmartThermostatDevice
    let period: SmartThermostatPeriod
    let periodInfo: SmartThermostatPeriodInfo
    
    let startTime: BehaviorSubject<Date>
    let coolTemp: BehaviorSubject<Temperature>
    let heatTemp: BehaviorSubject<Temperature>
    
    let minTime: Date
    let maxTime: Date
    
    let saveAction = PublishSubject<Void>()
    let saveTracker = ActivityTracker()
    
    var premiseNumber: String {
        return AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ??
            accountDetail.premiseNumber!
    }
    
    init(peakRewardsService: PeakRewardsService, accountDetail: AccountDetail, device: SmartThermostatDevice, period: SmartThermostatPeriod, schedule: SmartThermostatDeviceSchedule) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
        self.schedule = schedule
        self.device = device
        self.period = period
        self.periodInfo = schedule.info(for: period)
        
        self.startTime = BehaviorSubject(value: periodInfo.startTime)
        self.coolTemp = BehaviorSubject(value: periodInfo.coolTemp)
        self.heatTemp = BehaviorSubject(value: periodInfo.heatTemp)
        
        var subtractMinuteComponents = DateComponents()
        subtractMinuteComponents.minute = -15
        
        var addMinuteComponents = DateComponents()
        addMinuteComponents.minute = 15
        
        switch period {
        case .wake:
            minTime = Calendar.opCo.startOfDay(for: periodInfo.startTime)
            maxTime = Calendar.opCo.date(byAdding: subtractMinuteComponents, to: schedule.leaveInfo.startTime)!
        case .leave:
            minTime = Calendar.opCo.date(byAdding: addMinuteComponents, to: schedule.wakeInfo.startTime)!
            maxTime = Calendar.opCo.date(byAdding: subtractMinuteComponents, to: schedule.returnInfo.startTime)!
        case .return:
            minTime = Calendar.opCo.date(byAdding: addMinuteComponents, to: schedule.leaveInfo.startTime)!
            maxTime = Calendar.opCo.date(byAdding: subtractMinuteComponents, to: schedule.sleepInfo.startTime)!
        case .sleep:
            minTime = Calendar.opCo.date(byAdding: addMinuteComponents, to: schedule.returnInfo.startTime)!
            maxTime = Calendar.opCo.endOfDay(for: periodInfo.startTime)
        }
    }
    
    private(set) lazy var timeButtonText: Driver<String> = self.updatedPeriodInfo
        .map {
            let localizedTimeText = NSLocalizedString("Time: %@", comment: "")
            return String(format: localizedTimeText, $0.startTimeDisplayString)
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var updatedPeriodInfo: Observable<SmartThermostatPeriodInfo> = Observable
        .combineLatest(self.startTime,
                       self.coolTemp,
                       self.heatTemp,
                       resultSelector: SmartThermostatPeriodInfo.init)
    
    private lazy var saveEvents: Observable<Event<Void>> = self.saveAction
        .do(onNext: { [weak self] in
            guard let `self` = self else { return }
            let pageView: AnalyticsPageView
            switch self.period {
            case .wake:
                pageView = .wakeSave
            case .leave:
                pageView = .leaveSave
            case .return:
                pageView = .returnSave
            case .sleep:
                pageView = .sleepSave
            }
            Analytics.log(event: pageView)
        })
        .withLatestFrom(self.updatedPeriodInfo)
        .flatMapLatest { [weak self] periodInfo -> Observable<Event<Void>> in
            guard let `self` = self else { return .empty() }
            let updatedSchedule = self.schedule.newSchedule(forPeriod: self.period, info: periodInfo)
            return self.peakRewardsService.updateSmartThermostatSchedule(forDevice: self.device,
                                                                         accountNumber: self.accountDetail.accountNumber,
                                                                         premiseNumber: self.premiseNumber,
                                                                         schedule: updatedSchedule)
                .trackActivity(self.saveTracker)
                .materialize()
        }
        .share()
    
    private(set) lazy var saveSuccess: Observable<Void> = self.saveEvents.elements()
        .do(onNext: { [weak self] in
            guard let `self` = self else { return }
            let pageView: AnalyticsPageView
            switch self.period {
            case .wake:
                pageView = .wakeToast
            case .leave:
                pageView = .leaveToast
            case .return:
                pageView = .returnToast
            case .sleep:
                pageView = .sleepToast
            }
            Analytics.log(event: pageView)
        })
    private(set) lazy var saveError: Observable<String> = self.saveEvents.errors()
        .map { ($0 as? ServiceError)?.errorDescription ?? "" }
}
