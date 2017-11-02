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
    
    let peakRewardsService: PeakRewardsService
    
    let accountDetail: AccountDetail
    
    let peakRewardsSummaryFetchTracker = ActivityTracker()
    let deviceScheduleFetchTracker = ActivityTracker()
    
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
    
    private lazy var deviceScheduleEvents: Observable<Event<SmartThermostatDeviceSchedule>> = self.selectedDevice
        .flatMapLatest { [weak self] device -> Observable<Event<SmartThermostatDeviceSchedule>> in
            guard let `self` = self else { return .empty() }
            return self.peakRewardsService.fetchSmartThermostatSchedule(forDevice: device,
                                                                        accountNumber: self.accountDetail.accountNumber,
                                                                        premiseNumber: self.accountDetail.premiseNumber!)
                .trackActivity(self.deviceScheduleFetchTracker)
                .materialize()
        }
        .shareReplay(1)
    
    private(set) lazy var selectedDevice: Observable<SmartThermostatDevice> = Observable.merge(
        self.peakRewardsSummaryEvents.elements().map { $0.devices[0] }
    )
    
    private(set) lazy var peakRewardsPrograms: Driver<[PeakRewardsProgram]> = self.peakRewardsSummaryEvents.elements()
        .map { $0.programs }
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
