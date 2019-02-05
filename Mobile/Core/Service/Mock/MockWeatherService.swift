//
//  MockWeatherService.swift
//  Mobile
//
//  Created by Samuel Francis on 2/4/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MockWeatherService: WeatherService {
    func fetchWeather(address: String) -> Observable<WeatherItem> {
        let key = MockUser.current.currentAccount.dataKey(forFile: .weather)
        
        do {
            let weatherItem: WeatherItem = try MockJSONManager.shared.mappableObject(fromFile: .weather, key: key)
            return .just(weatherItem)
        } catch {
            return .error(error)
        }
    }
}
