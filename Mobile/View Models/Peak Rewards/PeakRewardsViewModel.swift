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
    
    let peakRewardsSummaryFetchTracker = ActivityTracker()
    let deviceScheduleFetchTracker = ActivityTracker()
    
    let selectedDeviceIndex = Variable(0)
    
    init(peakRewardsService: PeakRewardsService, accountDetail: AccountDetail) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
    }
    
    //MARK: - Web Requests
    private lazy var peakRewardsSummaryEvents: Observable<Event<PeakRewardsSummary>> = self.peakRewardsService
        .fetchPeakRewardsSummary(accountNumber: self.accountDetail.accountNumber,
                                 premiseNumber: self.accountDetail.premiseNumber!)
        .trackActivity(self.peakRewardsSummaryFetchTracker)
        .materialize()
        .shareReplay(1)
    
    private lazy var deviceScheduleEvents: Observable<Event<SmartThermostatDeviceSchedule>> = self.selectedDevice.asObservable()
        .flatMapLatest { [weak self] device -> Observable<Event<SmartThermostatDeviceSchedule>> in
            guard let `self` = self else { return .empty() }
            return self.peakRewardsService.fetchSmartThermostatSchedule(forDevice: device,
                                                                        accountNumber: self.accountDetail.accountNumber,
                                                                        premiseNumber: self.accountDetail.premiseNumber!)
                .trackActivity(self.deviceScheduleFetchTracker)
                .materialize()
        }
        .shareReplay(1)
    
    //MARK: View Values
    private(set) lazy var devices: Driver<[SmartThermostatDevice]> = self.peakRewardsSummaryEvents.elements()
        .map { $0.devices }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var selectedDevice: Driver<SmartThermostatDevice> = Observable
        .combineLatest(self.peakRewardsSummaryEvents.elements(),
                       self.rootScreenWillReappear.withLatestFrom(self.selectedDeviceIndex.asObservable().distinctUntilChanged()))
        .map { $0.devices[$1] }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var selectedDeviceName: Driver<String> = self.selectedDevice.map { $0.name }
    
    private(set) lazy var peakRewardsPrograms: Driver<[PeakRewardsProgram]> = self.peakRewardsSummaryEvents.elements()
        .map { $0.programs }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var deviceSchedule: Driver<SmartThermostatDeviceSchedule> = self.deviceScheduleEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    //MARK: - Show/Hide Views
    private(set) lazy var showMainLoadingState: Driver<Bool> = self.peakRewardsSummaryFetchTracker.asDriver()
    
    private(set) lazy var showMainErrorState: Driver<Bool> = Observable.merge(self.peakRewardsSummaryEvents.map { $0.error != nil },
                                                                              self.peakRewardsSummaryFetchTracker.asObservable().filter { $0 }.not())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMainContent: Driver<Bool> = Observable.merge(self.peakRewardsSummaryEvents.map { $0.error == nil },
                                                                           self.peakRewardsSummaryFetchTracker.asObservable().filter { $0 }.not())
        .asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var showScheduleLoadingState: Driver<Bool> = self.deviceScheduleFetchTracker.asDriver()
    private(set) lazy var showScheduleErrorState: Driver<Bool> = Observable.merge(self.deviceScheduleEvents.map { $0.error != nil },
                                                                                  self.deviceScheduleFetchTracker.asObservable().filter { $0 }.not())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showScheduleContent: Driver<Bool> = Observable.merge(self.deviceScheduleEvents.map { $0.error == nil },
                                                                               self.deviceScheduleFetchTracker.asObservable().filter { $0 }.not())
        .asDriver(onErrorDriveWith: .empty())
    
}
