//
//  HomeViewModel.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeViewModel {
    let defaultZip : String? = Environment.shared.opco == .bge ? "20201" : nil

    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    private let weatherService: WeatherService
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let usageService: UsageService
    private let authService: AuthenticationService
    private let outageService: OutageService
    
    let fetchData = PublishSubject<FetchingAccountState>()
    let fetchDataObservable: Observable<FetchingAccountState>

    let refreshFetchTracker = ActivityTracker()
    private let switchAccountFetchTracker = ActivityTracker()
    
    private let billTracker = ActivityTracker()
    private let usageTracker = ActivityTracker()
    private let accountDetailTracker = ActivityTracker()
    private let outageTracker = ActivityTracker()
    private let projectedBillTracker = ActivityTracker()
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshFetchTracker
        case .switchAccount:
            return switchAccountFetchTracker
        }
    }
    
    let latestNewCardVersion = HomeCard.latestNewCardVersion
    
    required init(accountService: AccountService,
                  weatherService: WeatherService,
                  walletService: WalletService,
                  paymentService: PaymentService,
                  usageService: UsageService,
                  authService: AuthenticationService,
                  outageService: OutageService) {
        self.fetchDataObservable = fetchData.share()
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
        self.usageService = usageService
        self.authService = authService
        self.outageService = outageService
    }
    
    private(set) lazy var weatherViewModel =
        HomeWeatherViewModel(accountDetailEvents: accountDetailEvents,
                             weatherService: weatherService,
                             usageService: usageService)
    
    private(set) lazy var billCardViewModel =
        HomeBillCardViewModel(fetchData: fetchDataObservable,
                              fetchDataMMEvents: fetchDataMMEvents,
                              accountDetailEvents: accountDetailEvents,
                              walletService: walletService,
                              paymentService: paymentService,
                              authService: authService,
                              refreshFetchTracker: refreshFetchTracker,
                              switchAccountFetchTracker: billTracker)
    
    private(set) lazy var usageCardViewModel =
        HomeUsageCardViewModel(fetchData: fetchDataObservable,
                               accountDetailEvents: accountDetailEvents,
                               usageService: usageService,
                               refreshFetchTracker: refreshFetchTracker,
                               switchAccountFetchTracker: usageTracker)
    
    private(set) lazy var templateCardViewModel: TemplateCardViewModel =
        TemplateCardViewModel(accountDetailEvents: accountDetailEvents,
                              showLoadingState: accountDetailTracker.asDriver()
                                .filter { $0 }
                                .map(to: ())
                                .startWith(()))
    
    private(set) lazy var projectedBillCardViewModel =
        HomeProjectedBillCardViewModel(fetchData: fetchDataObservable,
                                       accountDetailEvents: accountDetailEvents,
                                       usageService: usageService,
                                       refreshFetchTracker: refreshFetchTracker,
                                       switchAccountFetchTracker: projectedBillTracker)
    
    private(set) lazy var outageCardViewModel =
        HomeOutageCardViewModel(outageService: outageService,
                                maintenanceModeEvents: fetchDataMMEvents,
                                fetchDataObservable: fetchDataObservable,
                                refreshFetchTracker: refreshFetchTracker,
                                showLoadingState: isSwitchingAccounts.filter { $0 }.map(to: ()))
    
    private(set) lazy var isSwitchingAccounts = switchAccountFetchTracker.asDriver().map { $0 || AccountsStore.shared.currentAccount == nil }
    
    private lazy var fetchTrigger = Observable.merge(fetchDataObservable, RxNotifications.shared.accountDetailUpdated.map(to: FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var fetchDataMMEvents: Observable<Event<Maintenance>> = fetchData
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let this = self else { return nil }
            switch state {
            case .refresh:
                return [this.refreshFetchTracker]
            case .switchAccount:
                return [this.billTracker, this.usageTracker, this.accountDetailTracker, this.outageTracker, this.projectedBillTracker]
            }
            }, requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var accountDetailUpdatedMMEvents: Observable<Event<Maintenance>> = RxNotifications.shared.accountDetailUpdated
        .toAsyncRequest(activityTrackers: { [weak self] in
            guard let this = self else { return nil }
            return [this.billTracker, this.usageTracker, this.accountDetailTracker, this.outageTracker, this.projectedBillTracker]
            }, requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var maintenanceModeEvents: Observable<Event<Maintenance>> = Observable
        .merge(fetchDataMMEvents, accountDetailUpdatedMMEvents)
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = maintenanceModeEvents
        .filter { !($0.element?.homeStatus ?? false) }
        .withLatestFrom(fetchTrigger)
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let this = self else { return nil }
            switch state {
            case .refresh:
                return [this.refreshFetchTracker]
            case .switchAccount:
                return [this.billTracker, this.usageTracker, this.accountDetailTracker, this.projectedBillTracker]
            }
            }, requestSelector: { [weak self] _ in
                guard let this = self else { return .empty() }
                return this.accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
        })

    private lazy var accountDetailNoNetworkConnection: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private(set) lazy var showNoNetworkConnectionState: Driver<Bool> = {
        let noNetworkConnection = Observable.merge(accountDetailNoNetworkConnection,
                                                   billCardViewModel.walletItemNoNetworkConnection,
                                                   billCardViewModel.workDaysNoNetworkConnection)
            .asDriver(onErrorDriveWith: .empty())
        
        return Driver.combineLatest(noNetworkConnection,
                                    showMaintenanceModeState,
                                    switchAccountFetchTracker.asDriver()) { $0 && !$1 && !$2 }
            .startWith(false)
    }()
    
    private(set) lazy var showMaintenanceModeState: Driver<Bool> = Observable
        .combineLatest(maintenanceModeEvents.map { $0.element?.homeStatus ?? false },
                       switchAccountFetchTracker.asObservable()) { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowUsageCard: Driver<Bool> = accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()).map { accountDetail in
        guard let serviceType = accountDetail.serviceType else { return false }
        guard let _ = accountDetail.premiseNumber else { return false }
        
        if accountDetail.isBGEControlGroup {
            return accountDetail.isSERAccount // BGE Control Group + SER enrollment get the SER graph on usage card
        }
        
        if !accountDetail.isResidential || accountDetail.isFinaled {
            return false
        }
        
        // Must have valid serviceType
        if serviceType.uppercased() != "GAS" && serviceType.uppercased() != "ELECTRIC" && serviceType.uppercased() != "GAS/ELECTRIC" {
            return false
        }
        
        return true
    }
    
    private(set) lazy var shouldShowProjectedBillCard: Driver<Bool> = projectedBillCardViewModel.cardShouldBeHidden.not().asDriver(onErrorDriveWith: .empty())
    
}
