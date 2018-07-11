//
//  WeatherService.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift


protocol WeatherService {
    
    func getWeather(address: String, completion: @escaping (_ result: ServiceResult<WeatherItem>) -> Swift.Void)
}

extension WeatherService {
    
    //weather observable
    func fetchWeather(address: String) -> Observable<WeatherItem> {
        return Observable.create { observer in
            self.getWeather(address: address, completion: { (result: ServiceResult<WeatherItem>) in
                
                switch(result) {
                case .success(let weatherItem):
                    observer.onNext(weatherItem)
                    observer.onCompleted()
                    break
                case .failure(let error):
                    observer.onError(error)
                }
                
            })  
            return Disposables.create()
        }
    }
}
