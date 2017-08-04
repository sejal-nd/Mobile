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
    
    let disposeBag = DisposeBag()
    
    private let accountService: AccountService
    private let weatherService: WeatherService
    private let walletService: WalletService
    private let paymentService: PaymentService
    
    let fetchData = PublishSubject<FetchingAccountState>()
    
    let fetchingTracker = ActivityTracker()
    
    required init(accountService: AccountService, weatherService: WeatherService, walletService: WalletService, paymentService: PaymentService) {
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
    }
    
    private(set) lazy var billCardViewModel: HomeBillCardViewModel = HomeBillCardViewModel(withAccount: self.fetchData.map { _ in AccountsStore.sharedInstance.currentAccount },
                                                                                           accountDetailEvents: self.accountDetailEvents,
                                                                                           walletService: self.walletService,
                                                                                           paymentService: self.paymentService,
                                                                                           fetchingTracker: self.fetchingTracker)
    
    private(set) lazy var templateCardViewModel: TemplateCardViewModel = TemplateCardViewModel(accountDetailEvents: self.accountDetailEvents)
    
    private(set) lazy var isRefreshing: Driver<Bool> = Observable.combineLatest(self.fetchingTracker.asObservable(),
                                                                                self.fetchData.asObservable())
        .map { $0 && $1 == .refresh }
        .asDriver(onErrorJustReturn: false)
    
    private(set) lazy var isSwitchingAccounts: Driver<Bool> = Observable.combineLatest(self.fetchingTracker.asObservable(),
                                                                                       self.fetchData.asObservable())
        .map {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            return ($0 && $1 == .switchAccount)
        }
        .asDriver(onErrorJustReturn: false)
    
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = self.fetchData
        .map { _ in AccountsStore.sharedInstance.currentAccount }
        .unwrap()
        .flatMapLatest(self.fetchAccountDetail)
        .shareReplay(1)
    
    private func fetchAccountDetail(forAccount account: Account) -> Observable<Event<AccountDetail>> {
        return accountService.fetchAccountDetail(account: account)
            .trackActivity(self.fetchingTracker)
            .materialize()
    }
    
    let showTemplateCard = Environment.sharedInstance.opco != .comEd
    
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
    private lazy var weatherEvents: Observable<Event<WeatherItem>> = self.accountDetailEvents.elements()
        .map { $0.address ?? "" }
        .flatMapLatest(self.fetchWeather)
        .shareReplay(1)
    
    private func fetchWeather(forAddress address: String) -> Observable<Event<WeatherItem>> {
        return weatherService.fetchWeather(address: address)
            //.trackActivity(fetchingTracker)
            .materialize()
    }
    
    private(set) lazy var greeting: Driver<String?> = self.fetchData
        .map { _ in Date().localizedGreeting }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var weatherTemp: Driver<String?> = self.weatherEvents.elements()
        .map { "\($0.temperature)°" }
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var weatherIcon: Driver<UIImage?> = self.weatherEvents.elements()
        .map { $0.iconName != WeatherIconNames.UNKNOWN.rawValue ? UIImage(named: $0.iconName) : nil }
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var shortForecast: Driver<String?> = self.weatherEvents.elements()
        .map { $0.accessibilityName }
        .asDriver(onErrorJustReturn: nil)
    
    private lazy var weatherSuccess: Driver<Bool> = Observable.merge(self.accountDetailEvents.errors().map { _ in false },
                                                                     self.weatherEvents.errors().map { _ in false },
                                                                     self.accountDetailEvents.elements().map { _ in true },
                                                                     self.weatherEvents.elements().map { _ in true })
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showWeatherDetails: Driver<Bool> = Driver.combineLatest(self.isSwitchingAccounts, self.weatherSuccess)
        .map { !$0 && $1 }
    
}
