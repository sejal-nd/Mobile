//
//  TemperatureScaleStore.swift
//  Mobile
//
//  Created by Sam Francis on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
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

final class TemperatureScaleStore {
    
    static let shared = TemperatureScaleStore()
    
    // Private init protects against another instance being accidentally instantiated
    private init() { }
    
    private lazy var temperatureScaleCache =
        Variable<TemperatureScale>(
            TemperatureScale(rawValue: UserDefaults.standard.integer(forKey: UserDefaultKeys.TemperatureScale)) ?? .fahrenheit)
    
    var scale: TemperatureScale {
        get {
            return temperatureScaleCache.value
        }
        set(newValue) {
            temperatureScaleCache.value = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultKeys.TemperatureScale)
        }
    }
    
    private(set) lazy var scaleObservable: Observable<TemperatureScale> = self.temperatureScaleCache.asObservable()
        .shareReplay(1)
    
}

