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
    
    let fetchData = PublishSubject<FetchingAccountState>()
    let fetchDataObservable: Observable<FetchingAccountState>

    let refreshFetchTracker = ActivityTracker()
    private let switchAccountFetchTracker = ActivityTracker()
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshFetchTracker
        case .switchAccount:
            return switchAccountFetchTracker
        }
    }
    
    let latestNewCardVersion = HomeCard.latestNewCardVersion
    
    required init(accountService: AccountService, weatherService: WeatherService, walletService: WalletService, paymentService: PaymentService, usageService: UsageService, authService: AuthenticationService) {
        self.fetchDataObservable = fetchData.share()
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
        self.usageService = usageService
        self.authService = authService
    }
    
    private(set) lazy var weatherViewModel: HomeWeatherViewModel = HomeWeatherViewModel(accountDetailEvents: self.accountDetailEvents,
                                                                                        weatherService: self.weatherService,
                                                                                        usageService: self.usageService)
    
    private(set) lazy var billCardViewModel: HomeBillCardViewModel = HomeBillCardViewModel(fetchData: self.fetchDataObservable,
                                                                                           fetchDataMMEvents: self.fetchDataMMEvents,
                                                                                           accountDetailEvents: self.accountDetailEvents,
                                                                                           walletService: self.walletService,
                                                                                           paymentService: self.paymentService,
                                                                                           authService: self.authService,
                                                                                           refreshFetchTracker: self.refreshFetchTracker,
                                                                                           switchAccountFetchTracker: self.switchAccountFetchTracker)
    
    private(set) lazy var usageCardViewModel = HomeUsageCardViewModel(fetchData: self.fetchDataObservable,
                                                                      accountDetailEvents: self.accountDetailEvents,
                                                                      usageService: self.usageService,
                                                                      refreshFetchTracker: self.refreshFetchTracker,
                                                                      switchAccountFetchTracker: self.switchAccountFetchTracker)
    
    private(set) lazy var templateCardViewModel: TemplateCardViewModel = TemplateCardViewModel(accountDetailEvents: self.accountDetailEvents)
    
    private(set) lazy var isSwitchingAccounts = self.switchAccountFetchTracker.asDriver().map { $0 || AccountsStore.shared.currentAccount == nil }
    
    private lazy var fetchTrigger = Observable.merge(self.fetchDataObservable, RxNotifications.shared.accountDetailUpdated.map(to: FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var fetchDataMMEvents: Observable<Event<Maintenance>> = self.fetchData
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0) },
                        requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var accountDetailUpdatedMMEvents: Observable<Event<Maintenance>> = RxNotifications.shared.accountDetailUpdated
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: .switchAccount) },
                        requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var maintenanceModeEvents: Observable<Event<Maintenance>> = Observable.merge(self.fetchDataMMEvents, self.accountDetailUpdatedMMEvents)
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = self.maintenanceModeEvents
        .filter { !($0.element?.homeStatus ?? false) }
        .withLatestFrom(self.fetchTrigger)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0) },
                        requestSelector: { [unowned self] _ in
                            self.accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
        })

    private lazy var accountDetailNoNetworkConnection: Observable<Bool> = self.accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private(set) lazy var showNoNetworkConnectionState: Driver<Bool> = {
        let noNetworkConnection = Observable.merge(self.accountDetailNoNetworkConnection,
                                                   self.billCardViewModel.walletItemNoNetworkConnection,
                                                   self.billCardViewModel.workDaysNoNetworkConnection)
            .asDriver(onErrorDriveWith: .empty())
        
        return Driver.combineLatest(noNetworkConnection,
                                    self.showMaintenanceModeState,
                                    self.switchAccountFetchTracker.asDriver()) { $0 && !$1 && !$2 }
            .startWith(false)
    }()
    
    private(set) lazy var showMaintenanceModeState: Driver<Bool> = Observable
        .combineLatest(self.maintenanceModeEvents.map { $0.element?.homeStatus ?? false },
                       self.switchAccountFetchTracker.asObservable()) { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowUsageCard: Driver<Bool> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()).map { accountDetail in
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
    
}
