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
    
    private let alertsService: AlertsService
    private let gameService: GameService
    
    let fetchData = PublishSubject<Void>()
    let fetchDataObservable: Observable<Void>
    
    // A tracker for each card that loads data
    private let appointmentTracker = ActivityTracker()
    private let gameTracker = ActivityTracker()
    private let billTracker = ActivityTracker()
    private let usageTracker = ActivityTracker()
    private let accountDetailTracker = ActivityTracker()
    private let outageTracker = ActivityTracker()
    private let projectedBillTracker = ActivityTracker()
    
    let latestNewCardVersion = HomeCard.latestNewCardVersion
    let appointmentsUpdates = PublishSubject<[Appointment]>() // Bind the detail screen's poll results to this
    
    required init(alertsService: AlertsService,
                  gameService: GameService) {
        self.fetchDataObservable = fetchData.share()
        self.alertsService = alertsService
        self.gameService = gameService
    }
    
    private(set) lazy var appointmentCardViewModel =
        HomeAppointmentCardViewModel(appointments: appointments)
    
    private(set) lazy var weatherViewModel =
        HomeWeatherViewModel(accountDetailEvents: accountDetailEvents,
                             accountDetailTracker: accountDetailTracker)
    
    private(set) lazy var billCardViewModel =
        HomeBillCardViewModel(fetchData: fetchDataObservable,
                              fetchDataMMEvents: fetchDataMMEvents,
                              accountDetailEvents: accountDetailEvents,
                              scheduledPaymentEvents: scheduledPaymentEvents,
                                          fetchTracker: billTracker)
    
    private(set) lazy var usageCardViewModel =
        HomeUsageCardViewModel(fetchData: fetchDataObservable,
                               maintenanceModeEvents: maintenanceModeEvents,
                               accountDetailEvents: accountDetailEvents,
                               fetchTracker: usageTracker)
    
    private(set) lazy var templateCardViewModel =
        TemplateCardViewModel(accountDetailEvents: accountDetailEvents,
                              showLoadingState: accountDetailTracker.asDriver()
                                .filter { $0 }
                                .mapTo(())
                                .startWith(()))
    
    private(set) lazy var projectedBillCardViewModel =
        HomeProjectedBillCardViewModel(fetchData: fetchDataObservable,
                                       maintenanceModeEvents: maintenanceModeEvents,
                                       accountDetailEvents: accountDetailEvents,
                                       fetchTracker: projectedBillTracker)
    
    private(set) lazy var outageCardViewModel =
        HomeOutageCardViewModel(maintenanceModeEvents: fetchDataMMEvents,
                                fetchDataObservable: fetchDataObservable,
                                fetchTracker: outageTracker)
    
    private(set) lazy var prepaidActiveCardViewModel =
        HomePrepaidCardViewModel(isActive: true)
    
    private(set) lazy var prepaidPendingCardViewModel =
        HomePrepaidCardViewModel(isActive: false)
    
    private lazy var fetchTrigger = Observable.merge(fetchDataObservable, RxNotifications.shared.accountDetailUpdated, RxNotifications.shared.recentPaymentsUpdated)
    
    private lazy var recentPaymentsFetchTrigger = Observable
        .merge(fetchDataObservable, RxNotifications.shared.recentPaymentsUpdated)
    
    // Awful maintenance mode check
    private lazy var fetchDataMMEvents: Observable<Event<MaintenanceMode>> = fetchData
        .filter { _ in AccountsStore.shared.currentIndex != nil }
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let this = self else { return nil }
            return [this.appointmentTracker, this.gameTracker, this.billTracker, this.usageTracker, this.accountDetailTracker, this.outageTracker, this.projectedBillTracker]
        }, requestSelector: { [unowned self] _ in AnonymousService.rx.getMaintenanceMode(shouldPostNotification: true) })
    
    private lazy var accountDetailUpdatedMMEvents: Observable<Event<MaintenanceMode>> = RxNotifications.shared.accountDetailUpdated
        .filter { _ in AccountsStore.shared.currentIndex != nil }
        .toAsyncRequest(activityTrackers: { [weak self] in
            guard let this = self else { return nil }
            return [this.appointmentTracker, this.gameTracker, this.billTracker, this.usageTracker, this.accountDetailTracker, this.outageTracker, this.projectedBillTracker]
        }, requestSelector: { [weak self] _ in
            guard let self = self else { return .empty() }
            return AnonymousService.rx.getMaintenanceMode(shouldPostNotification: true)
        })
    
    private lazy var recentPaymentsUpdatedMMEvents: Observable<Event<MaintenanceMode>> = RxNotifications.shared.recentPaymentsUpdated
        .filter { _ in AccountsStore.shared.currentIndex != nil }
        .toAsyncRequest(activityTracker: billTracker) {
            AnonymousService.rx.getMaintenanceMode(shouldPostNotification: true)
        }
    
    private lazy var maintenanceModeEvents: Observable<Event<MaintenanceMode>> = Observable
        .merge(fetchDataMMEvents, accountDetailUpdatedMMEvents)
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = maintenanceModeEvents
        .filter { !($0.element?.all ?? false) && !($0.element?.home ?? false) }
        .withLatestFrom(fetchTrigger)
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let this = self else { return nil }
            return [this.billTracker, this.usageTracker, this.accountDetailTracker, this.projectedBillTracker]
        }, requestSelector: { [weak self] _ in
            guard let this = self else { return .empty() }
            return AccountService.rx.fetchAccountDetails()
            // todo account details
        })
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var scheduledPaymentEvents: Observable<Event<PaymentItem?>> = Observable
        .merge(fetchDataMMEvents, recentPaymentsUpdatedMMEvents)
        .filter {
            guard let maint = $0.element else { return true }
            return !maint.all && !maint.bill && !maint.home
        }
        .withLatestFrom(fetchTrigger)
        .toAsyncRequest(activityTrackers: { [weak self] state in
            guard let this = self else { return nil }
            return [this.billTracker]
        }, requestSelector: { [weak self] _ in
            guard let this = self else { return .empty() }
            return AccountService.rx.fetchScheduledPayments(accountNumber: AccountsStore.shared.currentAccount.accountNumber).map {
                return $0.last
            }
        })
        .share(replay: 1, scope: .forever)

    private lazy var accountDetailNoNetworkConnection: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue }
    
    private lazy var accountDetailAccountDisallow: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue }
    
    private(set) lazy var showNoNetworkConnectionState: Driver<Bool> = Driver
        .combineLatest(accountDetailNoNetworkConnection.asDriver(onErrorDriveWith: .empty()),
                       showMaintenanceModeState,
                       accountDetailTracker.asDriver())
        { $0 && !$1 && !$2 }
        .startWith(false)
        .distinctUntilChanged()
    
    private(set) lazy var showAccountDisallowState: Driver<Bool> = Driver
        .combineLatest(accountDetailAccountDisallow.asDriver(onErrorDriveWith: .empty()),
                       showMaintenanceModeState,
                       accountDetailTracker.asDriver())
        { $0 && !$1 && !$2 }
        .startWith(false)
        .distinctUntilChanged()
    
    private(set) lazy var showMaintenanceModeState: Driver<Bool> = Observable
        .combineLatest(maintenanceModeEvents.map { $0.element?.home ?? false },
                       accountDetailTracker.asObservable())
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var importantUpdate: Driver<OpcoUpdate?> = maintenanceModeEvents
        .filter { !($0.element?.all ?? false) && !($0.element?.home ?? false) }
        .toAsyncRequest { [weak self] _ in
            guard let this = self else { return .empty() }
            return this.alertsService.fetchOpcoUpdates(bannerOnly: true)
                .map { $0.first }
                .catchError { _ in .just(nil) }
        }
        .elements()
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var appointmentEvents = accountDetailEvents
        .elements()
        .withLatestFrom(fetchTrigger) { ($0, $1) }
        .toAsyncRequest(activityTrackers: { [weak self] (_, state) in
            guard let self = self else { return nil }
            return [self.appointmentTracker]
        }, requestSelector: { [weak self] (accountDetail, _) -> Observable<[Appointment]> in
            guard let self = self,
                let premiseNumber = accountDetail.premiseNumber else {
                return .empty()
            }
            
            return AppointmentService.rx.fetchAppointments(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumber: premiseNumber)
        })
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var appointments = Observable.merge(appointmentEvents.elements(), appointmentsUpdates)
    
    private(set) lazy var showAppointmentCard = Observable.just(Environment.shared.opco == .peco)
        .flatMap { shouldShow -> Observable<Bool> in
            if shouldShow {
                return Observable
                    .merge(self.appointmentEvents.map { !($0.element?.isEmpty ?? true) },
                           self.appointmentsUpdates.map { !$0.isEmpty },
                           self.appointmentTracker.asObservable().filter { $0 }.not())
            }
            else {
                return Observable.just(false)
            }
    }.asDriver(onErrorDriveWith: .empty())
    
    private lazy var gameUserEvents = accountDetailEvents
        .elements()
        .withLatestFrom(fetchTrigger) { ($0, $1) }
        .toAsyncRequest(activityTrackers: { [weak self] (_, state) in
            guard let self = self else { return nil }
            return [self.gameTracker]
        }, requestSelector: { [weak self] (accountDetail, _) -> Observable<GameUser?> in
            guard let self = self,
                Environment.shared.opco == .bge,
                AccountsStore.shared.currentAccount.isMultipremise == false,
                accountDetail.premiseNumber != nil,
                accountDetail.isAMIAccount,
                UI_USER_INTERFACE_IDIOM() != .pad else {
                return .just(nil)
            }
            
            return self.gameService.fetchGameUser(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
        })
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var showGameOnboardingCard = gameUserEvents.elements().asDriver(onErrorJustReturn: nil).map { user -> Bool in
        guard let gameUser = user else { return false }
        
        if gameUser.onboardingComplete && !gameUser.optedOut {
            NotificationCenter.default.post(name: .gameSetFabHidden, object: NSNumber(value: false))
        }
        return !gameUser.onboardingComplete && !gameUser.optedOut
    }
    
    private lazy var prepaidStatus = accountDetailEvents.elements()
        .mapAt(\.prepaidStatus)
        .startWith(.inactive)
        .distinctUntilChanged()
    
    private(set) lazy var prepaidCardViewModel: Driver<HomePrepaidCardViewModel?> = Observable
        .combineLatest(prepaidStatus, accountDetailTracker.asObservable())
        { prepaidStatus, isLoading -> HomePrepaidCardViewModel? in
            guard !isLoading else { return nil }
            switch prepaidStatus {
            case .active:
                return HomePrepaidCardViewModel(isActive: true)
            case .pending:
                return HomePrepaidCardViewModel(isActive: false)
            default:
                return nil
            }
        }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var cardPreferenceChanges = Observable
        .combineLatest(HomeCardPrefsStore.shared.listObservable, prepaidStatus)
        .scan(([HomeCard](), [HomeCard]())) { oldCards, newData in
            var (newCards, prepaidStatus) = newData
            
            switch prepaidStatus {
            case .active:
                // Active Prepaid replaces the bill card
                // Also remove usage and projected bill
                if let billIndex = newCards.firstIndex(of: .bill) {
                    newCards[billIndex] = .prepaidActive
                }
                
                newCards.removeAll { card in
                    switch card {
                    case .bill, .usage, .projectedBill:
                        return true
                    default:
                        return false
                    }
                }
            case .pending:
                // Pending Prepaid is always at the top
                newCards.insert(.prepaidPending, at: 0)
            default:
                break
            }
            
            return (oldCards.1, newCards)
        }
        .asDriver(onErrorDriveWith: .empty())
}
