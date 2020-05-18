//
//  GovWeatherService.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import CoreLocation
import Mapper

private let baseUrl = "https://api.weather.gov/"

struct GovWeatherService: WeatherService {
    
    let geoCoder = CLGeocoder()
    
    func fetchWeather(address: String) -> Observable<WeatherItem> {
        return Observable<String>
            .create { observer in
                self.geoCoder.geocodeAddressString(address) { placemarks, error in
                    guard let placemarks = placemarks,
                        placemarks.count > 0,
                        let coordinate = placemarks[0].location?.coordinate else {
                            observer.on(.error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: error)))
                            return
                    }
                    
                    observer.on(.next(self.urlString(coordinate: coordinate)))
                    observer.on(.completed)
                }
                
                return Disposables.create()
            }
            .flatMap { urlString -> Observable<WeatherItem> in
                let requestId = ShortUUIDGenerator.getUUID(length: 8)
                let method = HttpMethod.get
                APILog(GovWeatherService.self, requestId: requestId, path: urlString, method: method, logType: .request, message: nil)
                
                var urlRequest = URLRequest(url: URL(string: urlString)!)
                urlRequest.httpMethod = method.rawValue
                
                return URLSession.shared.rx.dataResponse(request: urlRequest, onCanceled: {
                    APILog(GovWeatherService.self, requestId: requestId, path: urlString, method: method, logType: .canceled, message: nil)
                }).do(onError: { error in
                    let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                    APILog(GovWeatherService.self, requestId: requestId, path: urlString, method: method, logType: .error, message: serviceError.errorDescription)
                }).map { data -> WeatherItem in
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                        let dict = json as? [String: Any],
                        let weatherItem = WeatherItem.from(dict as NSDictionary) else {
                            let error = ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                            APILog(GovWeatherService.self, requestId: requestId, path: urlString, method: method, logType: .error, message: error.errorDescription)
                            throw error
                    }
                    
                    APILog(GovWeatherService.self, requestId: requestId, path: urlString, method: method, logType: .response, message: "SUCCESS")
                    return weatherItem
                }
            }
        }
    
    private func urlString(coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.3f", coordinate.latitude)
        let lon = String(format: "%.3f", coordinate.longitude)
        return baseUrl + "points/\(lat),\(lon)/forecast/hourly"
    }
    
}
