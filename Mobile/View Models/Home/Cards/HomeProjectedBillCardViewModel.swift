//
//  HomeProjectedBillCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeProjectedBillCardViewModel {
    
    let disposeBag = DisposeBag()
    
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let usageService: UsageService
    
    private let fetchData: Observable<FetchingAccountState>
    
    let refreshFetchTracker: ActivityTracker
    let switchAccountFetchTracker: ActivityTracker
    let loadingTracker = ActivityTracker()
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshFetchTracker
        case .switchAccount: return switchAccountFetchTracker
        }
    }
    
    required init(fetchData: Observable<FetchingAccountState>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  usageService: UsageService,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.accountDetailEvents = accountDetailEvents
        self.usageService = usageService
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
    }
    
    private(set) lazy var shouldShowElectricGasSegmentedControl: Driver<Bool> = self.accountDetailEvents.map {
        $0.element?.serviceType?.uppercased() == "GAS/ELECTRIC"
    }
    .asDriver(onErrorDriveWith: .empty())
}
