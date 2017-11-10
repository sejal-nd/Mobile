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
    
    let rootScreenWillReappear = PublishSubject<Void>()
    let deviceScheduleChanged = PublishSubject<Void>()
    
    let peakRewardsSummaryFetchTracker = ActivityTracker()
    let deviceScheduleFetchTracker = ActivityTracker()
    
    let selectedDeviceIndex = Variable(0)
    
    init(peakRewardsService: PeakRewardsService, accountDetail: AccountDetail) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
    }
    
    var premiseNumber: String {
        return AccountsStore.sharedInstance.currentAccount.currentPremise?.premiseNumber ??
            accountDetail.premiseNumber!
    }
    
    //MARK: - Web Requests
    private lazy var peakRewardsSummaryEvents: Observable<Event<PeakRewardsSummary>> = self.peakRewardsService
        .fetchPeakRewardsSummary(accountNumber: self.accountDetail.accountNumber,
                                 premiseNumber: self.premiseNumber)
        .trackActivity(self.peakRewardsSummaryFetchTracker)
        .materialize()
        .share()
    
    private lazy var peakRewardsOverridesEvents: Observable<Event<[PeakRewardsOverride]>> = self.peakRewardsService
        .fetchPeakRewardsOverrides(accountNumber: self.accountDetail.accountNumber,
                                   premiseNumber: self.premiseNumber)
        .trackActivity(self.peakRewardsSummaryFetchTracker)
        .materialize()
        .share()
    
    private lazy var deviceScheduleEvents: Observable<Event<SmartThermostatDeviceSchedule?>> = Observable
        .merge(self.selectedDevice.asObservable(), self.deviceScheduleChanged.withLatestFrom(self.selectedDevice.asObservable()))
        .flatMapLatest { [weak self] device -> Observable<Event<SmartThermostatDeviceSchedule?>> in
            guard let `self` = self else { return .empty() }
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
        .shareReplay(1)
    
    //MARK: View Values
    private(set) lazy var devices: Driver<[SmartThermostatDevice]> = self.peakRewardsSummaryEvents.elements()
        .map { $0.devices }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var selectedDevice: Driver<SmartThermostatDevice> = Observable
        .combineLatest(self.peakRewardsSummaryEvents.elements(),
                       self.selectedDeviceIndex.asObservable().sample(self.rootScreenWillReappear).distinctUntilChanged())
        .map { $0.devices[$1] }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var selectedDeviceName: Driver<String> = self.selectedDevice.map { $0.name }
    
    private(set) lazy var peakRewardsPrograms: Driver<[PeakRewardsProgram]> = self.peakRewardsSummaryEvents.elements()
        .map { $0.programs }
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
    
    private(set) lazy var showMainErrorState: Driver<Bool> = Observable.merge(self.peakRewardsSummaryEvents.map { $0.error != nil },
                                                                              self.peakRewardsSummaryFetchTracker.asObservable().not().filter(!))
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMainContent: Driver<Bool> = Observable.merge(self.peakRewardsSummaryEvents.map { $0.error == nil },
                                                                           self.peakRewardsSummaryFetchTracker.asObservable().not().filter(!))
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showAdjustThermostatButton: Driver<Bool> = self.selectedDevice.map { $0.isSmartThermostat }
    
    private(set) lazy var showScheduleLoadingState: Driver<Bool> = self.deviceScheduleFetchTracker.asDriver()
    private(set) lazy var showScheduleErrorState: Driver<Bool> = Observable.merge(self.deviceScheduleEvents.map { $0.error != nil },
                                                                                  self.deviceScheduleFetchTracker.asObservable().not().filter(!))
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showScheduleContent: Driver<Bool> = Observable.merge(self.deviceScheduleEvents.map { $0.element != nil },
                                                                               self.deviceScheduleFetchTracker.asObservable().not().filter(!))
        .asDriver(onErrorDriveWith: .empty())
    
}
