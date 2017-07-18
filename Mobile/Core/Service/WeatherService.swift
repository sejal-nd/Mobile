//
//  WeatherService.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift


protocol WeatherService {
    
    func getWeather(address: String, completion: @escaping (_ result: ServiceResult<WeatherItemResult>) -> Swift.Void)
}

extension WeatherService {
    
    //weather observable
    func fetchWeather(address: String) -> Observable<WeatherItemResult> {
        return Observable.create { observer in
            self.getWeather(address: address, completion: { (result: ServiceResult<WeatherItemResult>) in
                
                switch(result) {
                case .Success(let weatherItemResult):
                    observer.onNext(weatherItemResult)
                    observer.onCompleted()
                    break
                case .Failure(let error):
                    observer.onError(error)
                }
                
            })  
            return Disposables.create()
        }
    }
}
