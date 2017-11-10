//
//  AdjustThermostatViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AdjustThermostatViewModel {
    let peakRewardsService: PeakRewardsService
    let accountDetail: AccountDetail
    
    var premiseNumber: String {
        return AccountsStore.sharedInstance.currentAccount.currentPremise?.premiseNumber ??
            accountDetail.premiseNumber!
    }
    
    let initialLoadTracker = ActivityTracker()
    
    let loadInitialData = PublishSubject<Void>()
    
    init(peakRewardsService: PeakRewardsService, accountDetail: AccountDetail, device: SmartThermostatDevice) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
    }
    
//    private(set) lazy var currentSettingsEvents: Observable<Event<SmartThermostatDeviceSettings>> = self.loadInitialData
//        .flatMapLatest { [weak self] _ -> Observable<Event<SmartThermostatDeviceSettings>> in
//            guard let `self` = self else { return .empty() }
//            return self.peakRewardsService.fetchDeviceSettings(accountNumber: self.accountDetail.accountNumber,
//                                                               premiseNumber: self.premiseNumber,
//                                                               device: self.device)
//                .trackActivity(self.initialLoadTracker)
//                .materialize()
//        }
//        .share()
    
}
