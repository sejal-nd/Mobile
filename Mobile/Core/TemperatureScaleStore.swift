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
    
    private let temperatureScaleCache: Variable<TemperatureScale>
    
    let scaleObservable: Observable<TemperatureScale>
    
    var scale: TemperatureScale {
        get {
            return temperatureScaleCache.value
        }
        set(newValue) {
            temperatureScaleCache.value = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultKeys.TemperatureScale)
        }
    }
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        let storedTempScale = UserDefaults.standard.integer(forKey: UserDefaultKeys.TemperatureScale)
        let initialScaleValue: TemperatureScale = TemperatureScale(rawValue: storedTempScale) ?? .fahrenheit
        temperatureScaleCache = Variable(initialScaleValue)
        
        scaleObservable = temperatureScaleCache.asObservable()
    }
}

