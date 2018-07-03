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
    
    private let bag = DisposeBag()
    
    private let maintenanceModeEvents: Observable<Event<Maintenance>>
    private let fetchDataObservable: Observable<FetchingAccountState>
    private let refreshFetchTracker: ActivityTracker
    private let switchAccountFetchTracker: ActivityTracker
    
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
    
    var currentOutageStatus: OutageStatus?

    private(set) lazy var powerStatusImage: Driver<UIImage> = self.outageStatusEvents.elements()
        .map { $0.activeOutage ? #imageLiteral(resourceName: "ic_lightbulb_off") : #imageLiteral(resourceName: "ic_outagestatus_on") }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var powerStatus: Driver<String> = self.outageStatusEvents.elements()
        .map { $0.activeOutage ? "POWER IS OFF" : "POWER IS ON" }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var restorationTime: Driver<String> = self.outageStatusEvents.elements()
        .map { "Estimated Restoration\n \(DateFormatter.outageOpcoDateFormatter.string(from: ($0.etr) ?? Date()))" }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var shouldShowRestorationTime: Driver<Bool> = self.outageStatusEvents.elements()
        .map { $0.etr == nil }
        .asDriver(onErrorDriveWith: .empty())
    
//    private(set) lazy var isGasOnly: Driver<Bool> = self.outageStatusEvents.elements()
//        .map { $0.flagGasOnly == nil }
//        .asDriver(onErrorDriveWith: .empty())
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshFetchTracker
        case .switchAccount:
            return switchAccountFetchTracker
        }
    }
    
    
    // MARK: - Service
    
    private func retrieveOutageStatus() -> Observable<OutageStatus> {
        //return ServiceFactory.createOutageService().fetchOutageStatus(account: AccountsStore.shared.currentAccount)
        
        let outageStatusObservable = ServiceFactory.createOutageService().fetchOutageStatus(account: AccountsStore.shared.currentAccount)
            
            let _ = outageStatusObservable.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] outageStatus in
                self?.currentOutageStatus = outageStatus
                }, onError: { [weak self] error in
                    guard let `self` = self else { return }
                    let serviceError = error as! ServiceError
                    if serviceError.serviceCode == ServiceErrorCode.fnAccountFinaled.rawValue {
                        self.currentOutageStatus = OutageStatus.from(["flagFinaled": true])
                    } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNoPay.rawValue {
                        self.currentOutageStatus = OutageStatus.from(["flagNoPay": true])
                    } else if serviceError.serviceCode == ServiceErrorCode.fnNonService.rawValue {
                        self.currentOutageStatus = OutageStatus.from(["flagNonService": true])
                    } else {
                        self.currentOutageStatus = nil
                    }
            })
        return outageStatusObservable
    }
    
}
