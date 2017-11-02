//
//  TemperatureScaleStore.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxSwiftExt

enum TemperatureScale: Int {
    case fahrenheit, celsius
    
    var displayString: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}

class TemperatureScaleStore {
    
    static let shared = TemperatureScaleStore()
    
    // Private init protects against another instance being accidentally instantiated
    private init() { }
    
    private var temperatureScaleCache: TemperatureScale?
    
    var scale: TemperatureScale {
        get {
            return temperatureScaleCache ??
                TemperatureScale(rawValue: UserDefaults.standard.integer(forKey: UserDefaultKeys.TemperatureScale)) ??
                .fahrenheit
        }
        set(newValue) {
            temperatureScaleCache = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultKeys.TemperatureScale)
        }
    }
    
    private(set) lazy var scaleObservable: Observable<TemperatureScale> = UserDefaults.standard.rx
        .observe(Int.self, UserDefaultKeys.TemperatureScale)
        .unwrap()
        .map(TemperatureScale.init)
        .unwrap()
        .startWith(self.scale)
        .shareReplay(1)
    
}
