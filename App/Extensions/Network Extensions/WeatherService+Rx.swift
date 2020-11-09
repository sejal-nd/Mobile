//
//  WeatherService+RX.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/29/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

extension WeatherService: ReactiveCompatible {}
extension Reactive where Base == WeatherService {
    static func getWeather(address: String) -> Observable<Weather> {
        return Observable.create { observer -> Disposable in
            WeatherService.getWeather(address: address) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
}
