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
    
    init(accountDetailEvents: Observable<Event<AccountDetail>>,
         weatherService: WeatherService,
         usageService: UsageService) {
        self.accountDetailEvents = accountDetailEvents
        self.weatherService = weatherService
        self.usageService = usageService
    }
    
    //MARK: - Weather
    private lazy var weatherEvents: Observable<Event<WeatherItem>> = self.accountDetailEvents.elements()
        .map { [unowned self] in AccountsStore.shared.currentAccount?.currentPremise?.zipCode ?? $0.zipCode ?? self.defaultZip }
        .unwrap()
        .flatMapLatest { [unowned self] in
            self.weatherService.fetchWeather(address: $0)
                .materialize()
        }
        .share(replay: 1)
    
    private(set) lazy var greeting: Driver<String?> = self.accountDetailEvents
        .map { _ in Date().localizedGreeting }
        .startWith(nil)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var weatherTemp: Driver<String?> = self.weatherEvents.elements()
        .map { "\($0.temperature)°F" }
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
    
    private(set) lazy var showWeatherDetails: Driver<Bool> = Observable.combineLatest(self.accountDetailEvents,
                                                                                      self.weatherEvents)
    { $0.error == nil && $1.error == nil }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var isTemperatureTipEligible: Observable<Bool> = Observable.combineLatest(self.weatherEvents.elements().asObservable(),
                                                                                                self.accountDetailEvents.elements())
    {
        if !$1.isResidential {
            return false
        }
        
        let opco = Environment.shared.opco
        
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
            switch Environment.shared.opco {
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
            switch Environment.shared.opco {
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
        { $0 && $1 }
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
