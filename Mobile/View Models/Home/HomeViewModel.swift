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
    private let accountService: AccountService
    private let weatherService: WeatherService
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let usageService: UsageService
    private let authService: AuthenticationService
    private let outageService: OutageService
    private let alertsService: AlertsService
    private let appointmentService: AppointmentService
    
    let fetchData = PublishSubject<FetchingAccountState>()
    let fetchDataObservable: Observable<FetchingAccountState>

    let refreshFetchTracker = ActivityTracker()
    
    // A tracker for each card that loads data
    private let appointmentTracker = ActivityTracker()
    private let billTracker = ActivityTracker()
    private let usageTracker = ActivityTracker()
    private let accountDetailTracker = ActivityTracker()
    private let outageTracker = ActivityTracker()
    private let projectedBillTracker = ActivityTracker()
    
    let latestNewCardVersion = HomeCard.latestNewCardVersion
    let appointmentsUpdates = PublishSubject<[Appointment]>() // Bind the detail screen's poll results to this
    
    required init(accountService: AccountService,
                  weatherService: WeatherService,
                  walletService: WalletService,
                  paymentService: PaymentService,
                  usageService: UsageService,
                  authService: AuthenticationService,
                  outageService: OutageService,
                  alertsService: AlertsService,
                  appointmentService: AppointmentService) {
        self.fetchDataObservable = fetchData.share()
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
        self.usageService = usageService
        self.authService = authService
        self.outageService = outageService
        self.alertsService = alertsService
        self.appointmentService = appointmentService
    }
    
    private(set) lazy var appointmentCardViewModel =
        HomeAppointmentCardViewModel(appointments: appointments)
    
    private(set) lazy var weatherViewModel =
        HomeWeatherViewModel(accountDetailEvents: accountDetailEvents,
                             weatherService: weatherService,
                             usageService: usageService,
                             accountDetailTracker: accountDetailTracker)
    
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
                               maintenanceModeEvents: maintenanceModeEvents,
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
                                       maintenanceModeEvents: maintenanceModeEvents,
                                       accountDetailEvents: accountDetailEvents,
                                       usageService: usageService,
                                       refreshFetchTracker: refreshFetchTracker,
                                       switchAccountFetchTracker: projectedBillTracker)
    
    private(set) lazy var outageCardViewModel =
        HomeOutageCardViewModel(outageService: outageService,
                                maintenanceModeEvents: fetchDataMMEvents,
                                fetchDataObservable: fetchDataObservable,
                                refreshFetchTracker: refreshFetchTracker,
                                switchAccountFetchTracker: outageTracker)
    
    private lazy var fetchTrigger = Observable.merge(fetchDataObservable, RxNotifications.shared.accountDetailUpdated.mapTo(FetchingAccountState.switchAccount))
    
    // Awful maintenance mode check
    private lazy var fetchDataMMEvents: Observable<Event<Maintenance>> = fetchData
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let this = self else { return nil }
            switch state {
            case .refresh:
                return [this.refreshFetchTracker]
            case .switchAccount:
                return [this.appointmentTracker, this.billTracker, this.usageTracker, this.accountDetailTracker, this.outageTracker, this.projectedBillTracker]
            }
            }, requestSelector: { [unowned self] _ in self.authService.getMaintenanceMode() })
    
    private lazy var accountDetailUpdatedMMEvents: Observable<Event<Maintenance>> = RxNotifications.shared.accountDetailUpdated
        .toAsyncRequest(activityTrackers: { [weak self] in
            guard let this = self else { return nil }
            return [this.appointmentTracker, this.billTracker, this.usageTracker, this.accountDetailTracker, this.outageTracker, this.projectedBillTracker]
            }, requestSelector: { [weak self] _ in
                guard let self = self else { return .empty() }
                return self.authService.getMaintenanceMode()
            })
    
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
        .share(replay: 1, scope: .forever)

    private lazy var accountDetailNoNetworkConnection: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private(set) lazy var showNoNetworkConnectionState: Driver<Bool> =  Driver
        .combineLatest(accountDetailNoNetworkConnection.asDriver(onErrorDriveWith: .empty()),
                       showMaintenanceModeState,
                       accountDetailTracker.asDriver())
        { $0 && !$1 && !$2 }
        .startWith(false)
        .distinctUntilChanged()
    
    private(set) lazy var showMaintenanceModeState: Driver<Bool> = Observable
        .combineLatest(maintenanceModeEvents.map { $0.element?.homeStatus ?? false },
                       accountDetailTracker.asObservable())
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var importantUpdate: Driver<OpcoUpdate?> = fetchDataObservable
        .toAsyncRequest { [weak self] _ in
            guard let this = self else { return .empty() }
            return this.alertsService.fetchOpcoUpdates(bannerOnly: true)
                .map { $0.first }
                .catchError { _ in .just(nil) }
        }
        .elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var appointmentEvents = accountDetailEvents
        .elements()
        .withLatestFrom(fetchTrigger) { ($0, $1) }
        .toAsyncRequest(activityTrackers: { [weak self] (_, state) in
            guard let self = self else { return nil }
            switch state {
            case .refresh:
                return [self.refreshFetchTracker]
            case .switchAccount:
                return [self.appointmentTracker]
            }
            }, requestSelector: { [weak self] (accountDetail, _) -> Observable<[Appointment]> in
                guard let self = self,
                    let premiseNumber = accountDetail.premiseNumber else {
                    return .empty()
                }
                
                return self.appointmentService
                    .fetchAppointments(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                       premiseNumber: premiseNumber)
        })
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var appointments = Observable.merge(appointmentEvents.elements(), appointmentsUpdates)
    
    private(set) lazy var showAppointmentCard = Observable
        .merge(appointmentEvents.map { !($0.element?.isEmpty ?? true) },
               appointmentsUpdates.map { !$0.isEmpty },
               appointmentTracker.asObservable().filter { $0 }.not())
        .asDriver(onErrorDriveWith: .empty())
}
