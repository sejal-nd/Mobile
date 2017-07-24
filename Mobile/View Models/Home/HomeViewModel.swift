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
    let currentAccount = Variable<Account?>(nil)
    
    let refreshTracker = ActivityTracker()
    let switchAccountsTracker = ActivityTracker()
    let fetchingTracker = ActivityTracker()
    
    required init(accountService: AccountService, weatherService: WeatherService, walletService: WalletService, paymentService: PaymentService) {
        self.accountService = accountService
        self.weatherService = weatherService
        self.walletService = walletService
        self.paymentService = paymentService
    }
    
    private(set) lazy var billCardViewModel: HomeBillCardViewModel = HomeBillCardViewModel(withAccount: self.currentAccount.asObservable().unwrap(),
                                                                                           accountDetailEvents: self.accountDetailEvents,
                                                                                           walletService: self.walletService,
                                                                                           paymentService: self.paymentService,
                                                                                           fetchingTracker: self.fetchingTracker)
    
    private(set) lazy var templateCardViewModel: TemplateCardViewModel = TemplateCardViewModel(accountDetailEvents: self.accountDetailEvents)
    
    private(set) lazy var accountDetailEvents: Observable<Event<AccountDetail>> = self.fetchData
        .withLatestFrom(self.currentAccount.asObservable()).debug("FETCH ACCOUNT DETAIL")
        .unwrap()
        .flatMapLatest(self.fetchAccountDetail)
        .shareReplay(1)
    
    private func fetchAccountDetail(forAccount account: Account) -> Observable<Event<AccountDetail>> {
        return accountService.fetchAccountDetail(account: account)
            .retry(.exponentialDelayed(maxCount: 2, initial: 2.0, multiplier: 1.5))
            .trackActivity(self.fetchingTracker)
            .materialize()
    }
    
    // Weather
    private lazy var weatherEvents: Observable<Event<WeatherItem>> = self.accountDetailEvents.elements()
        .map { $0.address ?? "" }
        .flatMap(self.weatherService.fetchWeather)
        .materialize()
    
    private(set) lazy var greeting: Driver<String?> = self.weatherEvents
        .map { _ in Date().localizedGreeting }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var weatherTemp: Driver<String?> = self.weatherEvents.elements()
        .map { "\($0.temperature)°" }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var weatherIcon: Driver<UIImage?> = self.weatherEvents.elements()
        .map { $0.iconName != WeatherIconNames.UNKNOWN.rawValue ? UIImage(named: $0.iconName) : nil }
        .asDriver(onErrorDriveWith: .empty())
    
}
