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

fileprivate let coldTips = ["tip080_set_thermostat_wisely_winter","tip033_clear_around_vents","tip046_let_in_sun_for_warmth"]

fileprivate let hotTips = ["tip021_let_ac_breathe","tip020_keep_out_solar_heat","tip084_use_fans_for_cooling"]

class HomeViewModel {
    let defaultZip : String? = Environment.sharedInstance.opco == .bge ? "20201" : nil;

    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    private let weatherService: WeatherService
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let usageService: UsageService
    
    let fetchData = PublishSubject<FetchingAccountState>()

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
    
    required init(accountService: AccountService, weatherService: WeatherService, walletService: WalletService, paymentService: PaymentService, usageService: UsageService) {
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
        self.usageService = usageService
    }
    
    private(set) lazy var billCardViewModel: HomeBillCardViewModel = HomeBillCardViewModel(fetchData: self.fetchData.asObservable(),
                                                                                           accountDetailEvents: self.accountDetailEvents,
                                                                                           walletService: self.walletService,
                                                                                           paymentService: self.paymentService,
                                                                                           refreshFetchTracker: self.refreshFetchTracker,
                                                                                           switchAccountFetchTracker: self.switchAccountFetchTracker)
    
    private(set) lazy var usageCardViewModel = HomeUsageCardViewModel(fetchData: self.fetchData.asObservable(),
                                                                      accountDetailEvents: self.accountDetailEvents,
                                                                      usageService: self.usageService,
                                                                      refreshFetchTracker: self.refreshFetchTracker,
                                                                      switchAccountFetchTracker: self.switchAccountFetchTracker)
    
    private(set) lazy var templateCardViewModel: TemplateCardViewModel = TemplateCardViewModel(accountDetailEvents: self.accountDetailEvents)
    
    private(set) lazy var isSwitchingAccounts = self.switchAccountFetchTracker.asDriver().map { $0 || AccountsStore.sharedInstance.currentAccount == nil }
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = Observable
        .merge(self.fetchData.asObservable(), RxNotifications.shared.accountDetailUpdated.mapTo(FetchingAccountState.switchAccount))
        .flatMapLatest { [unowned self] in
            self.accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                .trackActivity(self.fetchTracker(forState: $0))
                .materialize()
        }
        .shareReplay(1)

    private lazy var accountDetailNoNetworkConnection: Observable<Bool> = self.accountDetailEvents
        .map { ($0.error as? ServiceError)?.serviceCode == ServiceErrorCode.NoNetworkConnection.rawValue }
    
    private(set) lazy var showNoNetworkConnectionState: Driver<Bool> = {
        let noNetworkConnection = Observable.merge(self.accountDetailNoNetworkConnection,
                                                   self.billCardViewModel.walletItemNoNetworkConnection,
                                                   self.billCardViewModel.workDaysNoNetworkConnection)
            .asDriver(onErrorDriveWith: .empty())
        
        return Driver.combineLatest(noNetworkConnection, self.switchAccountFetchTracker.asDriver()) { $0 && !$1 }
    }()
    
    //MARK: - Weather
    private lazy var weatherEvents: Observable<Event<WeatherItem>> = self.accountDetailEvents.elements()
        .withLatestFrom(
            Observable.combineLatest(
                self.fetchData.map{ _ in AccountsStore.sharedInstance.currentAccount }
                    .unwrap()
                    .map { $0.currentPremise?.zipCode },
                self.accountDetailEvents.elements()
                    .map { [unowned self] in $0.zipCode ?? self.defaultZip } // TODO: Get default zip for current opco
            )
        )
        .map { $0 ?? $1 }
        .unwrap()
        .flatMapLatest { [unowned self] in
            self.weatherService.fetchWeather(address: $0)
                .materialize()
        }
        .shareReplay(1)

    private(set) lazy var greeting: Driver<String?> = self.accountDetailEvents
        .map { _ in Date().localizedGreeting }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var weatherTemp: Driver<String?> = self.weatherEvents.elements()
        .map { "\($0.temperature)°" }
        .startWith(nil)
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var weatherIcon: Driver<UIImage?> = self.weatherEvents.elements()
        .map { $0.iconName != WeatherIconNames.UNKNOWN.rawValue ? UIImage(named: $0.iconName) : nil }
        .startWith(nil)
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var weatherIconA11yLabel: Driver<String?> = self.weatherEvents.elements()
        .map { $0.accessibilityName }
        .startWith(nil)
        .asDriver(onErrorJustReturn: nil)

    private(set) lazy var showWeatherDetails: Driver<Bool> = Observable.combineLatest(self.switchAccountFetchTracker.asObservable(),
                                                                                      self.accountDetailEvents,
                                                                                      self.weatherEvents)
        { !$0 && $1.error == nil && $2.error == nil }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowUsageCard: Driver<Bool> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty()).map { accountDetail in
        guard let serviceType = accountDetail.serviceType else { return false }
        guard let premiseNumber = accountDetail.premiseNumber else { return false }
        
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
    
    private(set) lazy var isTemperatureTipEligible: Observable<Bool> = Observable.combineLatest(self.weatherEvents.elements().asObservable(),
                                                                                                self.accountDetailEvents.elements())
        {
            if !$1.isResidential {
                return false
            }
            
            let opco = Environment.sharedInstance.opco
            
            if (opco == .comEd || opco == .peco) && $1.isFinaled {
                return false
            }
            
            if $1.isBGEControlGroup {
                return false
            }
            
            if opco == .bge && ($1.serviceType ?? "").isEmpty {
                return false
            }
            
            return true
        }
    
    private(set) lazy var isHighTemperature: Observable<Bool> = self.weatherEvents.elements()
        .map {
            switch Environment.sharedInstance.opco {
            case .bge:
                return $0.temperature >= 86
            case .comEd:
                return $0.temperature >= 81
            case .peco:
                return $0.temperature >= 80
            }
        }
    
    private(set) lazy var isLowTemperature: Observable<Bool> = self.weatherEvents.elements()
        .map {
            switch Environment.sharedInstance.opco {
            case .bge:
                return $0.temperature <= 32
            case .comEd:
                return $0.temperature <= 21
            case .peco:
                return $0.temperature <= 27
            }
    }
    
    private(set) lazy var showTemperatureTip: Driver<Bool> = Observable
        .combineLatest(self.temperatureTipRequestData.map { ($0 || $1) && $2.premiseNumber != nil && $3 },
                       self.temperatureTipEvents.map { $0.error == nil })
        {
            $0 && $1
        }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var temperatureTipText: Driver<String?> = Observable.combineLatest(self.isTemperatureTipEligible,
                                                                                         self.isHighTemperature,
                                                                                         self.isLowTemperature)
    {
        guard $0 else { return nil }
        if $1 {
            return NSLocalizedString("High Temperature Tip", comment: "")
        } else if $2 {
            return NSLocalizedString("Low Temperature Tip", comment: "")
        } else {
            return nil
        }
        }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var temperatureTipImage: Driver<UIImage?> = Observable.combineLatest(self.isTemperatureTipEligible,
                                                                                           self.isHighTemperature,
                                                                                           self.isLowTemperature)
    {
        guard $0 else { return nil }
        if $1 {
            return #imageLiteral(resourceName: "ic_home_hightemp")
        } else if $2 {
            return #imageLiteral(resourceName: "ic_home_lowtemp")
        } else {
            return nil
        }
        }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var temperatureTipRequestData: Observable<(Bool, Bool, AccountDetail, Bool)> = Observable
        .combineLatest(self.isHighTemperature,
                       self.isLowTemperature,
                       self.accountDetailEvents.elements(),
                       self.isTemperatureTipEligible)
    
    private lazy var temperatureTipEvents: Observable<Event<String>> = self.temperatureTipRequestData
        .filter { ($0 || $1) && $2.premiseNumber != nil && $3 }
        .flatMapLatest { [weak self] isHigh, isLow, accountDetail, _ -> Observable<Event<String>> in
            guard let `self` = self else { return .empty() }
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            
            let randomNumber = Int(arc4random_uniform(3))
            let tipName = isHigh ? hotTips[randomNumber] : coldTips[randomNumber]
            
            return self.usageService.fetchEnergyTipByName(accountNumber: accountDetail.accountNumber,
                                                          premiseNumber: premiseNumber,
                                                          tipName: tipName)
                .map { $0.body }
                .materialize()
    }
    
    private(set) lazy var temperatureTipModalData: Driver<(title: String, image: UIImage, body: String)> = Observable
        .combineLatest(self.temperatureTipEvents.elements(),
                       self.temperatureTipText.asObservable().unwrap(),
                       self.isHighTemperature)
        { temperatureTip, title, isHigh in
            let image = isHigh ? #imageLiteral(resourceName: "img_hightemp") : #imageLiteral(resourceName: "img_lowtemp")
            return (title, image, temperatureTip)
        }
        .asDriver(onErrorDriveWith: .empty())

}
