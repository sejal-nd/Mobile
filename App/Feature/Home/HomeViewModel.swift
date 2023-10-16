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
import UIKit

class HomeViewModel {
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
    

    required init() {
        self.fetchDataObservable = fetchData.share()
    }
    
    private(set) lazy var appointmentCardViewModel =
        HomeAppointmentCardViewModel(appointments: appointments)
    
    private(set) lazy var weatherViewModel =
        HomeWeatherViewModel(accountDetailEvents: accountDetailEvents,
                             accountDetailTracker: accountDetailTracker)

    private(set) lazy var discoverCardViewModel =
        HomeDiscoverCardViewModel(accountDetailEvents: accountDetailEvents)
    
    private(set) lazy var billCardViewModel =
        HomeBillCardViewModel(fetchData: fetchDataObservable,
                              fetchDataMMEvents: fetchDataMMEvents,
                              accountDetailEvents: accountDetailEvents.share(scope: .forever),
                              scheduledPaymentEvents: scheduledPaymentEvents,
                                          fetchTracker: billTracker)
    
    private(set) lazy var usageCardViewModel =
        HomeUsageCardViewModel(fetchData: fetchDataObservable,
                               maintenanceModeEvents: maintenanceModeEvents,
                               accountDetailEvents: accountDetailEvents,
                               fetchTracker: usageTracker)
    
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
    
    private(set) lazy var gameCardViewModel = GameHomeViewModel()
    
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
            guard let this = self, !UserSession.isRefreshTokenExpired else { return .empty() }
            return AccountService.rx.fetchScheduledPayments(accountNumber: AccountsStore.shared.currentAccount.accountNumber).map {
                return $0.last
            }
        })
        .share(replay: 1, scope: .forever)

    private lazy var accountDetailNoNetworkConnection: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? NetworkingError) == .noNetwork }
    
    private lazy var accountDetailAccountDisallow: Observable<Bool> = accountDetailEvents
        .map { ($0.error as? NetworkingError) == .blockAccount }
    
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
    
    private(set) lazy var importantUpdate: Driver<Alert?> = maintenanceModeEvents
        .filter { !($0.element?.all ?? false) && !($0.element?.home ?? false) }
        .toAsyncRequest { [weak self] _ in
            guard let this = self else { return .empty() }
            return AlertService.rx.fetchAlertBanner(bannerOnly: true, stormOnly: false)
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
    
    private(set) lazy var showAppointmentCard = Observable.just(Configuration.shared.opco == .peco)
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
                Configuration.shared.opco == .bge,
                AccountsStore.shared.currentAccount.isMultipremise == false,
                accountDetail.premiseNumber != nil,
                accountDetail.isAMIAccount,
                UI_USER_INTERFACE_IDIOM() != .pad else {
                return .just(nil)
            }
            
            return GameService.rx.fetchGameUser(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
        })
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var showGameOnboardingCard = gameUserEvents.elements().asDriver(onErrorJustReturn: nil).map { user -> Bool in
        guard let gameUser = user else { return false }
        return !gameUser.onboardingComplete && !gameUser.optedOut
    }
    
    private(set) lazy var gameUser = gameUserEvents.asDriver(onErrorDriveWith: .empty()).map { event -> GameUser? in
        guard let gameUser = event.element, !(gameUser?.optedOut ?? false) else { return nil }
        return gameUser
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
        .combineLatest(HomeCardPrefsStore.shared.listObservable, prepaidStatus, accountDetailEvents.elements(), gameUser.asObservable())
        .map({ (cards, prepaidStatus, accountDetails, gameUser) -> ([HomeCard], AccountDetail.PrepaidStatus) in
            var newCards = cards
            /* Legacy logic for hiding card for BGE when not enrolled in Peak Rewards
            if Configuration.shared.opco == .bge && accountDetails.isResidential {
                switch accountDetails.peakRewards {
                case "ACTIVE"?, "ECOBEE WIFI"?:
                    break
                default:
                    for (index, card) in newCards.enumerated() {
                        switch card {
                        case .template:
                            newCards.remove(at: index)
                        default:
                            break
                        }
                    }
                }
            }
            */
            
            if FeatureFlagUtility.shared.bool(forKey: .isGamificationEnabled) == false || Configuration.shared.opco != .bge || gameUser == nil || gameUser?.optedOut == true {
                for (index, card) in newCards.enumerated() {
                    switch card {
                    case .game:
                        newCards.remove(at: index)
                    default:
                        break
                    }
                }
            }
            
            return (newCards, prepaidStatus)
        })
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
    
    lazy var makePaymentScheduledPaymentAlertInfo: Observable<(String?, String?, AccountDetail)> = Observable
        .combineLatest(accountDetailEvents.elements(), scheduledPaymentEvents.elements())
          .map { accountDetail, scheduledPayment in
              if Configuration.shared.opco == .bge && accountDetail.isBGEasy {
                  return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You are already " +
                      "enrolled in our BGEasy direct debit payment option. BGEasy withdrawals process on the due date " +
                      "of your bill from the bank account you originally submitted. You may make a one-time payment " +
                      "now, but it may result in duplicate payment processing. Do you want to continue with a " +
                      "one-time payment?", comment: ""), accountDetail)
              } else if accountDetail.isAutoPay {
                  return (NSLocalizedString("Existing Automatic Payment", comment: ""), NSLocalizedString("You currently " +
                      "have automatic payments set up. To avoid a duplicate payment, please review your payment " +
                      "activity before proceeding. Would you like to continue making an additional payment?\n\nNote: " +
                      "If you recently enrolled in AutoPay and you have not yet received a new bill, you will need " +
                      "to submit a payment for your current bill if you have not already done so.", comment: ""), accountDetail)
              } else if let scheduledPaymentAmount = scheduledPayment?.amount,
                  let scheduledPaymentDate = scheduledPayment?.date,
                  scheduledPaymentAmount > 0 {
                  let localizedTitle = NSLocalizedString("Existing Scheduled Payment", comment: "")
                  return (localizedTitle, String(format: NSLocalizedString("You have a payment of %@ scheduled for %@. " +
                      "To avoid a duplicate payment, please review your payment activity before proceeding. Would " +
                      "you like to continue making an additional payment?", comment: ""),
                                                 scheduledPaymentAmount.currencyString, scheduledPaymentDate.mmDdYyyyString), accountDetail)
              }
              return (nil, nil, accountDetail)
      }
    
    private let phonePromptInterval: TimeInterval = 60 * 60 * 24 * 365 // 365 days
    private(set) lazy var showPhoneNumberPrompt = accountDetailEvents.elements().map {
            Configuration.shared.opco == .comEd && $0.customerInfo.primaryPhoneNumber?.contains("9999999") == true
        }.filter {
            if $0 {
                if let lastPrompt = UserDefaults.standard.object(forKey: UserDefaultKeys.updatePhoneNumberReminderTimestamp) as? Date {
                    let nextPrompt = Date(timeInterval: self.phonePromptInterval, since: lastPrompt)
                    return nextPrompt < Date.now
                } else {
                    return true
                }
            }
            
            return false
        }
    
    var contactPrefsWebUrl: String {
        switch Configuration.shared.opco {
        case .comEd:
            return "https://\(Configuration.shared.associatedDomain)/MyAccount/MyProfile/Pages/Secure/MyReportsAndAlerts.aspx"
        default:
            return ""
        }
    }

    var backgroundImage: UIImage? {
        let components = Calendar.current.dateComponents([.hour], from: .now)
        guard let hour = components.hour else { return UIImage(named: "img_home_afternoon_mobile") }

        if UIDevice.current.userInterfaceIdiom == .pad {
            if 4 ... 11 ~= hour {
                return UIImage(named: "img_home_morning_tablet_portrait")
            } else if 11 ... 15 ~= hour {
                return UIImage(named: "img_home_afternoon_tablet_portrait")
            } else {
                return UIImage(named: "img_home_evening_tablet_portrait")
            }
        } else {
            if 4 ... 11 ~= hour {
                return UIImage(named: "img_home_morning_mobile")
            } else if 11 ... 15 ~= hour {
                return UIImage(named: "img_home_afternoon_mobile")
            } else {
                return UIImage(named: "img_home_evening_mobile")
            }
        }
    }

    private(set) lazy var backgroundImageDriver: Driver<UIImage?> = Observable<Int>
        .interval(.seconds(60), scheduler: MainScheduler.instance)
        .mapTo(())
        .startWith(())
        .map { self.backgroundImage }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var greetingDriver: Driver<String?> = Observable<Int>
        .interval(.seconds(60), scheduler: MainScheduler.instance)
        .mapTo(())
        .startWith(())
        .map { Date.now.localizedGreeting }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var greetingDateDriver: Driver<String?> = Observable<Int>
        .interval(.seconds(60), scheduler: MainScheduler.instance)
        .mapTo(())
        .startWith(())
        .map { NSLocalizedString("It's \(DateFormatter.dayMonthDayYearFormatter.string(from: Date.now))", comment: "") }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
}
