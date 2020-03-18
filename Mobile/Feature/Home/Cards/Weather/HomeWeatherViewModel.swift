//
//  HomeWeatherViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 6/4/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

fileprivate let coldTips = ["tip080_set_thermostat_wisely_winter","tip033_clear_around_vents","tip046_let_in_sun_for_warmth"]

fileprivate let hotTips = ["tip021_let_ac_breathe","tip020_keep_out_solar_heat","tip084_use_fans_for_cooling"]

class HomeWeatherViewModel {
    let defaultZip : String? = Environment.shared.opco == .bge ? "20201" : nil
    
    let accountDetailEvents: Observable<Event<AccountDetail>>
    let weatherService: WeatherService
    let usageService: UsageService
    
    let accountDetailTracker: ActivityTracker
    
    init(accountDetailEvents: Observable<Event<AccountDetail>>,
         weatherService: WeatherService,
         usageService: UsageService,
         accountDetailTracker: ActivityTracker) {
        self.accountDetailEvents = accountDetailEvents
        self.weatherService = weatherService
        self.usageService = usageService
        self.accountDetailTracker = accountDetailTracker
    }
    
    //MARK: - Weather
    private lazy var weatherEvents: Observable<Event<WeatherItem>> = accountDetailEvents.elements()
        .map { [weak self] in
            guard AccountsStore.shared.currentIndex != nil else {
                return nil
            }
            
            return AccountsStore.shared.currentAccount.currentPremise?.zipCode ?? $0.zipCode ?? self?.defaultZip
        }
        .unwrap()
        .toAsyncRequest { [weak self] in
            self?.weatherService.fetchWeather(address: $0) ?? .empty()
        }
    
    private(set) lazy var greeting: Driver<String?> = Observable<Int>
        .interval(.seconds(60), scheduler: MainScheduler.instance)
//        .map { "\($0)" }
        .mapTo(())
        .startWith(())
        .map { Date.now.localizedGreeting }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var weatherTemp: Driver<String?> = weatherEvents.elements()
        .map { "\($0.temperature)°F" }
        .startWith(nil)
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var weatherIcon: Driver<UIImage?> = weatherEvents.elements()
        .map { $0.iconName != WeatherIconNames.unknown.rawValue ? UIImage(named: $0.iconName) : nil }
        .startWith(nil)
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var weatherIconA11yLabel: Driver<String?> = weatherEvents.elements()
        .map { $0.accessibilityName }
        .startWith(nil)
        .asDriver(onErrorJustReturn: nil)
    
    private(set) lazy var showWeatherDetails: Driver<Bool> = Observable
        .merge(
            accountDetailTracker.asObservable().filter { $0 }.mapTo(false),
            weatherEvents.elements().mapTo(true)
        )
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showTemperatureTip: Driver<Bool> = Observable
        .merge(
            accountDetailTracker.asObservable().filter { $0 }.mapTo(false),
            temperatureTipEvents.map { $0.error == nil }
        )
        .startWith(false)
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    
    private(set) lazy var temperatureTipText: Driver<String?> = Observable
        .combineLatest(accountDetailEvents.elements(),
                       weatherEvents.elements())
        { accountDetail, weatherItem in
            guard accountDetail.isEligibleForUsageData else { return nil }
            if weatherItem.isHighTemperature {
                return NSLocalizedString("High Temperature Tip", comment: "")
            } else if weatherItem.isLowTemperature {
                return NSLocalizedString("Low Temperature Tip", comment: "")
            } else {
                return nil
            }
        }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var temperatureTipImage: Driver<UIImage?> = Observable
        .combineLatest(accountDetailEvents.elements(),
                       weatherEvents.elements())
        { accountDetail, weatherItem in
            guard accountDetail.isEligibleForUsageData else { return nil }
            if weatherItem.isHighTemperature {
                return #imageLiteral(resourceName: "ic_home_hightemp")
            } else if weatherItem.isLowTemperature {
                return #imageLiteral(resourceName: "ic_home_lowtemp")
            } else {
                return nil
            }
        }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var temperatureTipEvents: Observable<Event<String>> = weatherEvents.elements()
        .withLatestFrom(accountDetailEvents.elements()) { ($0, $1) }
        .filter { ($0.isHighTemperature || $0.isLowTemperature) && $1.isEligibleForUsageData }
        .toAsyncRequest { [weak self] weatherItem, accountDetail -> Observable<String> in
            guard let this = self else { return .empty() }
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            
            let randomIndex = Int.random(in: 0...2)
            let tipName = weatherItem.isHighTemperature ? hotTips[randomIndex] : coldTips[randomIndex]
            
            return this.usageService.fetchEnergyTipByName(accountNumber: accountDetail.accountNumber,
                                                          premiseNumber: premiseNumber,
                                                          tipName: tipName)
                .map { $0.body }
    }
    
    private(set) lazy var temperatureTipModalData: Driver<(title: String, image: UIImage, body: String, onClose: (() -> ())?)> = Observable
        .combineLatest(temperatureTipEvents.elements(),
                       temperatureTipText.asObservable().unwrap(),
                       weatherEvents.elements())
        { temperatureTip, title, weatherItem in
            let image = weatherItem.isHighTemperature ? #imageLiteral(resourceName: "img_hightemp") : #imageLiteral(resourceName: "img_lowtemp")
            return (title, image, temperatureTip, nil)
        }
        .asDriver(onErrorDriveWith: .empty())
}

fileprivate extension WeatherItem {
    
    var isHighTemperature: Bool {
        switch Environment.shared.opco {
        case .bge:
            return temperature >= 86
        case .comEd:
            return temperature >= 81
        case .peco:
            return temperature >= 80
        }
    }
    
    var isLowTemperature: Bool {
        switch Environment.shared.opco {
        case .bge:
            return temperature <= 32
        case .comEd:
            return temperature <= 21
        case .peco:
            return temperature <= 27
        }
    }
    
}

