//
//  AdjustThermostatViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AdjustThermostatViewModel {
    let peakRewardsService: PeakRewardsService
    let accountDetail: AccountDetail
    let device: SmartThermostatDevice
    
    var premiseNumber: String {
        return AccountsStore.sharedInstance.currentAccount.currentPremise?.premiseNumber ??
            accountDetail.premiseNumber!
    }
    
    let currentTemperature = BehaviorSubject<Temperature>(value: Temperature(value: Double(70), scale: .fahrenheit))
    let mode = BehaviorSubject<SmartThermostatMode>(value: .cool)
    
    let initialLoadTracker = ActivityTracker()
    let saveTracker = ActivityTracker()
    
    let saveAction = PublishSubject<Void>()
    let loadInitialData = PublishSubject<Void>()
    
    init(peakRewardsService: PeakRewardsService, accountDetail: AccountDetail, device: SmartThermostatDevice) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
        self.device = device
    }
    
    private lazy var currentSettingsEvents: Observable<Event<SmartThermostatDeviceSettings>> = self.loadInitialData
        .flatMapLatest { [weak self] _ -> Observable<Event<SmartThermostatDeviceSettings>> in
            guard let `self` = self else { return .empty() }
            return self.peakRewardsService.fetchDeviceSettings(accountNumber: self.accountDetail.accountNumber,
                                                               premiseNumber: self.premiseNumber,
                                                               device: self.device)
                .trackActivity(self.initialLoadTracker)
                .materialize()
        }
        .share()
    
    private lazy var initialSettings: Driver<SmartThermostatDeviceSettings> = self.currentSettingsEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var initialTemp: Driver<Temperature> = self.initialSettings.map { $0.temp }
    private(set) lazy var initialMode: Driver<SmartThermostatMode> = self.initialSettings.map { $0.mode }
    private(set) lazy var initialFan: Driver<SmartThermostatFan> = self.initialSettings.map { $0.fan }
    private(set) lazy var initialHold: Driver<Bool> = self.initialSettings.map { $0.hold }
    
    private(set) lazy var showMainLoadingState: Driver<Bool> = self.initialLoadTracker.asDriver()
    
    private(set) lazy var showMainContent: Driver<Bool> = Observable
        .combineLatest(self.currentSettingsEvents.map { $0.error == nil },
                       self.initialLoadTracker.asObservable().not().filter(!))
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showErrorLabel: Driver<Bool> = Observable
        .combineLatest(self.currentSettingsEvents.map { $0.error != nil },
                       self.initialLoadTracker.asObservable().not().filter(!))
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
//    private lazy var saveEvents: Observable<Event<Void>> = self.saveAction.withLatestFrom(self.updatedPeriodInfo)
//        .flatMapLatest { [weak self] periodInfo -> Observable<Event<Void>> in
//            guard let `self` = self else { return .empty() }
//            let updatedSchedule = self.schedule.newSchedule(forPeriod: self.period, info: periodInfo)
//            return self.peakRewardsService.updateSmartThermostatSchedule(forDevice: self.device,
//                                                                         accountNumber: self.accountDetail.accountNumber,
//                                                                         premiseNumber: self.premiseNumber,
//                                                                         schedule: updatedSchedule)
//                .trackActivity(self.saveTracker)
//                .materialize()
//        }
//        .share()
//
//    private(set) lazy var saveSuccess: Observable<Void> = self.saveEvents.elements()
//    private(set) lazy var saveError: Observable<String> = self.saveEvents.errors()
//        .map { ($0 as? ServiceError)?.errorDescription ?? "" }
    
}
