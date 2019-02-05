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
        let dataFile = MockJSONManager.File.weather
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }
}
