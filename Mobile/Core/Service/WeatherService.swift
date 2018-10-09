//
//  WeatherService.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol WeatherService {
    func fetchWeather(address: String) -> Observable<WeatherItem>
}
