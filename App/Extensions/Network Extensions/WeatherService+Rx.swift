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
        print("Retrieving weather service info: ADDRESS\(address)")
        return Observable.create { observer -> Disposable in
            WeatherService.getWeather(address: address) { result in
                switch result {
                case .success(let weather):
                    observer.onNext(weather)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
