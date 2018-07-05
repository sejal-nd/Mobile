//
//  HomeOutageCardViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeOutageCardViewModel {
    
    private let maintenanceModeEvents: Observable<Event<Maintenance>>
    private let fetchDataObservable: Observable<FetchingAccountState>
    private let refreshFetchTracker: ActivityTracker
    private let switchAccountFetchTracker: ActivityTracker
    
    
    // MARK: - INIT
    
    required init(maintenanceModeEvents: Observable<Event<Maintenance>>,
                  fetchDataObservable: Observable<FetchingAccountState>,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        print("init outage")
        self.maintenanceModeEvents = maintenanceModeEvents
        self.fetchDataObservable = fetchDataObservable
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
    }
    
    
    // MARK: - Retrieve Outage Status
    
    private lazy var outageStatusEvents: Observable<Event<OutageStatus>> = self.maintenanceModeEvents
        .filter { !($0.element?.outageStatus ?? false) && !($0.element?.homeStatus ?? false) }
        .withLatestFrom(self.fetchDataObservable)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0) },
                        requestSelector: { [unowned self] _ in
                            self.retrieveOutageStatus()
        })
    
    
    // MARK: - Variables
    
    private(set) lazy var currentOutageStatus: Driver<OutageStatus> = self.outageStatusEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowContentView: Driver<Bool> = Driver.combineLatest(isOutageErrorStatus, shouldShowMaintenanceModeState, isGasOnly)
        { !$0 && !$1 && !$2 }
    
    private lazy var isOutageErrorStatus: Driver<Bool> = self.outageStatusEvents
        .asDriver(onErrorDriveWith: .empty())
        .map { $0.error != nil }
        .startWith(false)

    private(set) lazy var shouldShowErrorState: Driver<Bool> = Driver.combineLatest(isOutageErrorStatus, shouldShowMaintenanceModeState)
        { $0 && !$1 }
    
    private(set) lazy var shouldShowMaintenanceModeState: Driver<Bool> = self.maintenanceModeEvents
        .map { $0.element?.outageStatus ?? false }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var powerStatusImage: Driver<UIImage> = self.currentOutageStatus
        .map { $0.activeOutage ? #imageLiteral(resourceName: "ic_lightbulb_off") : #imageLiteral(resourceName: "ic_outagestatus_on") }
    
    private(set) lazy var powerStatus: Driver<String> = self.currentOutageStatus
        .map { $0.activeOutage ? "POWER IS OFF" : "POWER IS ON" }
    
    private(set) lazy var restorationTime: Driver<String> = self.currentOutageStatus
        .map { "Estimated Restoration\n \(DateFormatter.outageOpcoDateFormatter.string(from: ($0.etr) ?? Date()))" }

    private(set) lazy var shouldShowRestorationTime: Driver<Bool> = self.currentOutageStatus
        .map { $0.etr == nil }
    
    private lazy var isGasOnly: Driver<Bool> = self.outageStatusEvents
        .map { $0.element?.flagGasOnly ?? false }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowGasOnly: Driver<Bool> = Driver.combineLatest(isGasOnly, shouldShowMaintenanceModeState)
        { $0 && !$1 }
    
    let hasReportedOutage = BehaviorSubject<Bool>(value: false)
    
    
    // MARK: - Service
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshFetchTracker
        case .switchAccount:
            return switchAccountFetchTracker
        }
    }
    
    private func retrieveOutageStatus() -> Observable<OutageStatus> {
        return ServiceFactory.createOutageService().fetchOutageStatus(account: AccountsStore.shared.currentAccount)
            .catchError { error -> Observable<OutageStatus> in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnAccountFinaled.rawValue {
                    return .just(OutageStatus.from(["flagFinaled": true])!)
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNoPay.rawValue {
                    return .just(OutageStatus.from(["flagNoPay": true])!)
                } else if serviceError.serviceCode == ServiceErrorCode.fnNonService.rawValue {
                    return .just(OutageStatus.from(["flagNonService": true])!)
                } else {
                    return .error(serviceError)
                }
        }
    }
    
}
