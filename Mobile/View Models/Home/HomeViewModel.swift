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
    let defaultZip : String? = Environment.sharedInstance.opco == .bge ? "20201" : nil;

    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    private let weatherService: WeatherService
    private let walletService: WalletService
    private let paymentService: PaymentService
    private let usageService: UsageService
    
    let fetchData = PublishSubject<FetchingAccountState>()

    let fetchingTracker = ActivityTracker()
    
    required init(accountService: AccountService, weatherService: WeatherService, walletService: WalletService, paymentService: PaymentService, usageService: UsageService) {
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
        self.usageService = usageService
    }
    
    private(set) lazy var billCardViewModel: HomeBillCardViewModel = HomeBillCardViewModel(withAccount: self.fetchData.map { _ in AccountsStore.sharedInstance.currentAccount },
                                                                                           accountDetailEvents: self.accountDetailEvents,
                                                                                           walletService: self.walletService,
                                                                                           paymentService: self.paymentService,
                                                                                           fetchingTracker: self.fetchingTracker)
    
    private(set) lazy var usageCardViewModel = HomeUsageCardViewModel(accountDetailEvents: self.accountDetailEvents,
                                                                      usageService: self.usageService,
                                                                      fetchingTracker: self.fetchingTracker)
    
    private(set) lazy var templateCardViewModel: TemplateCardViewModel = TemplateCardViewModel(accountDetailEvents: self.accountDetailEvents)
    
    private(set) lazy var isRefreshing: Driver<Bool> = Observable.combineLatest(self.fetchingTracker.asObservable().skip(1),
                                                                                self.fetchData.asObservable())
        .map { $0 && $1 == .refresh }
        .asDriver(onErrorJustReturn: false)
    
    private(set) lazy var isSwitchingAccounts: Driver<Bool> = Observable.combineLatest(self.fetchingTracker.asObservable().skip(1),
                                                                                       self.fetchData.asObservable())
        .do(onNext: { _ in UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil) })
        .map { $0 && $1 == .switchAccount }
        .asDriver(onErrorJustReturn: false)
    
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = Observable.merge(self.fetchData.mapTo(()),
                                                                                                   RxNotifications.shared.accountDetailUpdated)
        .map { AccountsStore.sharedInstance.currentAccount }
        .unwrap()
        .flatMapLatest { [unowned self] in
            self.accountService.fetchAccountDetail(account: $0)
                .trackActivity(self.fetchingTracker)
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
        
        return Driver.combineLatest(noNetworkConnection, self.isSwitchingAccounts) { $0 && !$1 }
    }()
    
    //MARK: - Weather
    private lazy var weatherEvents: Observable<Event<WeatherItem>> = Observable.combineLatest(
                    self.fetchData.map{ _ in AccountsStore.sharedInstance.currentAccount }.unwrap().map {
                        $0.currentPremise?.zipCode
                    },
                    self.accountDetailEvents.elements().map { [unowned self] in $0.zipCode ?? self.defaultZip } // TODO: Get default zip for current opco
            ).map{ $0 ?? $1 }.unwrap().flatMapLatest { [unowned self] in
                self.weatherService.fetchWeather(address: $0)
                        //.trackActivity(fetchingTracker)
                        .materialize()
            }.shareReplay(1)

    private(set) lazy var greeting: Driver<String?> = self.fetchData
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


    private lazy var weatherSuccess: Driver<Bool> = Observable.merge(self.accountDetailEvents.errors().map { _ in false },
                                                                     self.weatherEvents.errors().map { _ in false },
                                                                     self.accountDetailEvents.elements().map { _ in true },
                                                                     self.weatherEvents.elements().map { _ in true })
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showWeatherDetails: Driver<Bool> = Driver.combineLatest(self.isSwitchingAccounts, self.weatherSuccess)
        .map { !$0 && $1 }
    
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
    
    private(set) lazy var showTemperatureTip: Driver<Bool> = Observable.combineLatest(self.showWeatherDetails.asObservable(),
                                                                                      self.isTemperatureTipEligible,
                                                                                      self.isHighTemperature,
                                                                                      self.isLowTemperature)
    { $0 && $1 && ($2 || $3) }
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
    
    private(set) lazy var temperatureTipModalData: Driver<(title: String, image: UIImage, body: String)> = Observable
        .combineLatest(self.isHighTemperature,
                       self.temperatureTipText.asObservable().unwrap())
        {
            let title = $1
            let image = $0 ? #imageLiteral(resourceName: "img_hightemp") : #imageLiteral(resourceName: "img_lowtemp")
            let body = """
                Depending where you live in the country, cooling can account for a significant portion of your home's energy bill. In some southern climates, it can easily account for half of the cost, particularly in homes having air conditioning.
                
                The type of cooling system and the amount of energy it uses depends largely on local climate. However, the home's characteristics and the resident's personal needs play roles as well.
                """
            
            return (title, image, body)
        }
        .asDriver(onErrorDriveWith: .empty())

}
