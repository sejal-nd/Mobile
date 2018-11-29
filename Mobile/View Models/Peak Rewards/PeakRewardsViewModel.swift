//
//  PeakRewardsViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class PeakRewardsViewModel {
    
    let disposeBag = DisposeBag()
    
    let peakRewardsService: PeakRewardsService
    let accountDetail: AccountDetail
    
    var premiseNumber: String {
        return AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ??
            accountDetail.premiseNumber!
    }
    
    let selectedDeviceIndex = BehaviorSubject(value: 0)
    
    let peakRewardsSummaryFetchTracker = ActivityTracker()
    let deviceScheduleFetchTracker = ActivityTracker()
    
    //MARK: - Actions
    let loadInitialData = PublishSubject<Void>()
    let overridesUpdated = PublishSubject<Void>()
    let deviceScheduleChanged = PublishSubject<Void>()
    
    //MARK: - Init
    init(peakRewardsService: PeakRewardsService, accountDetail: AccountDetail) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
    }
    
    //MARK: - Web Requests
    private lazy var peakRewardsSummaryEvents: Observable<Event<PeakRewardsSummary>> = self.loadInitialData
        .flatMapLatest { [weak self] _ -> Observable<Event<PeakRewardsSummary>> in
            guard let self = self else { return .empty() }
            return self.peakRewardsService
                .fetchPeakRewardsSummary(accountNumber: self.accountDetail.accountNumber,
                                         premiseNumber: self.premiseNumber)
                .trackActivity(self.peakRewardsSummaryFetchTracker)
                .materialize()
                .filter { !$0.isCompleted }
        }
        .share(replay: 1)
    
    private(set) lazy var peakRewardsOverridesEvents: Observable<Event<[PeakRewardsOverride]>> = Observable
        .merge(self.loadInitialData, self.overridesUpdated)
        .flatMapLatest { [weak self] _ -> Observable<Event<[PeakRewardsOverride]>> in
            guard let self = self else { return .empty() }
            return self.peakRewardsService
                .fetchPeakRewardsOverrides(accountNumber: self.accountDetail.accountNumber,
                                           premiseNumber: self.premiseNumber)
                .trackActivity(self.peakRewardsSummaryFetchTracker)
                .materialize()
                .filter { !$0.isCompleted }
        }
        .share(replay: 1)
    
    private(set) lazy var overrides: Observable<[PeakRewardsOverride]> = self.peakRewardsOverridesEvents.elements()
    
    private lazy var summaryAndOverridesEvents: Observable<(Event<PeakRewardsSummary>, Event<[PeakRewardsOverride]>)> = Observable
        .combineLatest(self.peakRewardsSummaryEvents, self.peakRewardsOverridesEvents)
    
    private lazy var summaryAndOverridesErrors: Observable<Error> = self.summaryAndOverridesEvents
        .map { $0.error ?? $1.error }
        .unwrap()
    
    private lazy var programsAndOverridesElements: Observable<(PeakRewardsSummary, [PeakRewardsOverride])> = self.summaryAndOverridesEvents
        .map { summaryEvent, overridesEvent -> (PeakRewardsSummary, [PeakRewardsOverride])? in
            guard let summary = summaryEvent.element, let overrides = overridesEvent.element else { return nil }
            return (summary, overrides)
        }
        .unwrap()
    
    private lazy var deviceScheduleEvents: Observable<Event<SmartThermostatDeviceSchedule?>> = Observable
        .merge(self.selectedDevice.asObservable(), self.deviceScheduleChanged.withLatestFrom(self.selectedDevice.asObservable()))
        .flatMapLatest { [weak self] device -> Observable<Event<SmartThermostatDeviceSchedule?>> in
            guard let self = self else { return .empty() }
            guard device.isSmartThermostat else {
                return Observable.just(Event<SmartThermostatDeviceSchedule?>.next(nil))
            }
            
            return self.peakRewardsService.fetchSmartThermostatSchedule(forDevice: device,
                                                                        accountNumber: self.accountDetail.accountNumber,
                                                                        premiseNumber: self.premiseNumber)
                .map { $0 } // Type inference makes this optional
                .trackActivity(self.deviceScheduleFetchTracker)
                .materialize()
                .filter { !$0.isCompleted }
        }
        .share(replay: 1)
    
    //MARK: - View Values
    private(set) lazy var devices: Driver<[SmartThermostatDevice]> = self.peakRewardsSummaryEvents.elements()
        .map { $0.devices }
        .do(onNext: { [weak self] devices in
            if let (index, thermostat) = devices.enumerated().first(where: { $0.1.isSmartThermostat }) {
                self?.selectedDeviceIndex.onNext(index)
            } else {
                self?.selectedDeviceIndex.onNext(0)
            }
        })
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var selectedDevice: Driver<SmartThermostatDevice> = Observable
        .combineLatest(peakRewardsSummaryEvents.elements(),
                       selectedDeviceIndex.asObservable().skip(1).distinctUntilChanged())
        .map { $0.devices[$1] }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var deviceButtonText: Driver<String> = self.selectedDevice.map {
        String(format: NSLocalizedString("Device: %@", comment: ""), $0.name)
    }
    
    private(set) lazy var programCardsData: Driver<[(String, String)]> = Observable
        .combineLatest(programsAndOverridesElements, selectedDevice.asObservable())
        .map { pair, selectedDevice -> [(String, String)] in
            let (summary, overrides) = pair
            
            let programs = summary.programs.filter { selectedDevice.programNames.contains($0.name) }
            let override = overrides.filter {
                guard let start = $0.start else { return false }
                return $0.serialNumber == selectedDevice.serialNumber && Calendar.opCo.isDateInToday(start)
                }.first
            
            return programs
                .sorted { program1, program2 in
                    !program1.displayName.lowercased().contains("localized") &&
                        program2.displayName.lowercased().contains("localized")
                }
                .map { program -> (String, String) in
                    let body: String
                    switch (program.status, override?.status) {
                    case (.active, .active?):
                        body = NSLocalizedString("Override scheduled for today", comment: "")
                    case (.active, .scheduled?): fallthrough
                    case (.active, .none):
                        body = NSLocalizedString("Currently cycling", comment: "")
                    case (.inactive, .active?):
                        body = NSLocalizedString("Override scheduled for today", comment: "")
                    case (.inactive, .scheduled?):
                        if let start = override?.start, Calendar.opCo.isDateInToday(start) && override?.stop != nil {
                            body = NSLocalizedString("You have been cycled today", comment: "")
                        } else {
                            body = NSLocalizedString("You have not been cycled today", comment: "")
                        }
                    case (.inactive, .none):
                        if program.stopDate == nil {
                            body = NSLocalizedString("You have not been cycled today", comment: "")
                        } else if let startDate = program.startDate, Calendar.opCo.isDateInToday(startDate) {
                            body = NSLocalizedString("You have been cycled today", comment: "")
                        } else {
                            body = NSLocalizedString("You have not been cycled today", comment: "")
                        }
                    }
                    
                    return (program.displayName, body)
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var deviceSchedule: Driver<SmartThermostatDeviceSchedule> = self.deviceScheduleEvents.elements()
        .unwrap()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var wakeInfo: Driver<SmartThermostatPeriodInfo> = self.deviceSchedule.map { $0.wakeInfo }
    private(set) lazy var leaveInfo: Driver<SmartThermostatPeriodInfo> = self.deviceSchedule.map { $0.leaveInfo }
    private(set) lazy var returnInfo: Driver<SmartThermostatPeriodInfo> = self.deviceSchedule.map { $0.returnInfo }
    private(set) lazy var sleepInfo: Driver<SmartThermostatPeriodInfo> = self.deviceSchedule.map { $0.sleepInfo }

    //MARK: - Show/Hide Views
    private(set) lazy var showMainLoadingState: Driver<Bool> = self.peakRewardsSummaryFetchTracker.asDriver()
    
    private(set) lazy var showMainErrorState: Driver<Bool> = Observable
        .combineLatest(self.summaryAndOverridesEvents.map { $0.0.error ?? $0.1.error != nil },
                       self.peakRewardsSummaryFetchTracker.asObservable())
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMainContent: Driver<Bool> = Observable
        .combineLatest(self.summaryAndOverridesEvents.map { $0.0.error == nil && $0.1.error == nil },
                       self.peakRewardsSummaryFetchTracker.asObservable())
        .map { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showDeviceButton: Driver<Bool> = self.devices.map { $0.count > 1 }
    private(set) lazy var selectedDeviceIsSmartThermostat: Driver<Bool> = self.selectedDevice.map { $0.isSmartThermostat }
    
    private(set) lazy var showScheduleLoadingState: Driver<Bool> = self.deviceScheduleFetchTracker.asDriver()
    private(set) lazy var showScheduleErrorState: Driver<Bool> = Observable
        .combineLatest(self.deviceScheduleEvents.map { $0.error != nil },
                       self.deviceScheduleFetchTracker.asObservable())
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showScheduleContent: Driver<Bool> = Observable
        .combineLatest(
            self.deviceScheduleEvents.map {
                if case .next(let value) = $0 {
                    return value != nil
                } else {
                    return false
                }
            },
            self.deviceScheduleFetchTracker.asObservable()
        )
        .map { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
}
