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
    
    init(accountDetail: AccountDetail, device: SmartThermostatDevice, period: SmartThermostatPeriod, schedule: SmartThermostatDeviceSchedule) {
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
        .map { $0.startTimeDisplayString }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var timeButtonA11yText: Driver<String> = self.timeButtonText
        .map { String.localizedStringWithFormat("Time: %@", $0) }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var updatedPeriodInfo: Observable<SmartThermostatPeriodInfo> = Observable
        .combineLatest(self.startTime,
                       self.coolTemp,
                       self.heatTemp,
                       resultSelector: SmartThermostatPeriodInfo.init)
    
    private lazy var saveEvents: Observable<Event<Void>> = self.saveAction
        .do(onNext: { [weak self] in
            guard let self = self else { return }
            let pageView: GoogleAnalyticsEvent
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
            GoogleAnalytics.log(event: pageView)
        })
        .withLatestFrom(self.updatedPeriodInfo)
        .flatMapLatest { [weak self] periodInfo -> Observable<Event<Void>> in
            guard let self = self else { return .empty() }
            let updatedSchedule = self.schedule.newSchedule(forPeriod: self.period, info: periodInfo)
            return PeakRewardsService.rx.updateSmartThermostatSchedule(accountNumber: self.accountDetail.accountNumber,
                                                                         premiseNumber: self.premiseNumber,
                                                                         deviceSerialNumber: self.device.serialNumber,
                                                                         schedule: updatedSchedule)
                .trackActivity(self.saveTracker)
                .materialize()
        }
        .share()
    
    private(set) lazy var saveSuccess: Observable<Void> = self.saveEvents.elements()
        .do(onNext: { [weak self] in
            guard let self = self else { return }
            let pageView: GoogleAnalyticsEvent
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
            GoogleAnalytics.log(event: pageView)
        })
    private(set) lazy var saveError: Observable<String> = self.saveEvents.errors()
        .map { ($0 as? ServiceError)?.errorDescription ?? "" }
    
    var didYouKnowText: String {
        switch self.period {
        case .wake:
            return NSLocalizedString("As a guideline, the U.S. Department of Energy suggests setting your thermostat to 68°F for heating and 78°F for cooling while you are awake at home.", comment: "")
        case .leave:
            return NSLocalizedString("Program the thermostat to an energy-saving level for when your household members are away. Setting your home's temperature at least 10°F higher in the summer and 10°F lower in the winter is a good rule of thumb.", comment: "")
        case .return:
            return NSLocalizedString("As a guideline, the U.S. Department of Energy suggests setting your thermostat to 68°F for heating and 78°F for cooling while you are awake at home.", comment: "")
        case .sleep:
            return NSLocalizedString("Program your thermostat at least 10°F lower in the winter or 4°F higher in the summer while you're sleeping. The temperature will return to your preferred comfort level by the time you wake up.", comment: "")
        }
    }
}
