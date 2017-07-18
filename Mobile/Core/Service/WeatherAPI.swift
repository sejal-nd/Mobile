//
//  weatherAPI.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import CoreLocation

let baseUrl = "https://api.weather.gov/"

struct WeatherItemResult {
    let temperature : NSNumber
    let icon : UIImage
}

private enum ResponseKey : String {
    case Properties = "properties"
    case Periods = "periods"
    case Temperature = "temperature"
    case Icon = "icon"
}

struct WeatherAPI { 
    
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


    private func getWeather(address: String, completion: @escaping (_ result: ServiceResult<WeatherItemResult>) -> Swift.Void) {
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in 
            if let placemarks = placemarks,
                placemarks.count > 0,
                let coordinate = placemarks[0].location?.coordinate { 
                let urlString = self.urlString(coordinate: coordinate)
                
                var urlRequest = URLRequest(url: URL(string: urlString)!)
                urlRequest.httpMethod = "GET"
                URLSession.shared.dataTask(with:urlRequest, completionHandler: { (data:Data?, resp: URLResponse?, err: Error?) in
                    if let error = err {
                        let serviceError = ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, cause: error)
                        completion(ServiceResult.Failure(serviceError))
                        
                    } else {
                        let responseString = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
                        dLog(message: responseString)
                        
                        do {
                            let resultDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                            completion(ServiceResult.Success(self.weatherItemFrom(data: resultDictionary)!))  //TODO: don't force this
                            
                        }
                        catch let error as NSError {
                            let serviceError = ServiceError(serviceCode: ServiceErrorCode.Parsing.rawValue, cause: error)
                            completion(ServiceResult.Failure(serviceError))
                        }
                    }
                }).resume()
                
            }
        })
    }
    
    private func urlString(coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(coordinate.latitude)
        let lon = String(coordinate.longitude)
        return baseUrl + "points/\(lat),\(lon)/forecast/hourly"
        
    }
    
    private func weatherItemFrom(data: Dictionary<String, Any?>?) -> WeatherItemResult? {
        guard let properties = data?[ResponseKey.Properties.rawValue] as? Dictionary<String, Any>,
            let periods = properties[ResponseKey.Periods.rawValue] as? Array<[String: Any]>,
            let temp = periods[0][ResponseKey.Temperature.rawValue] as? NSNumber,
            let iconString = periods[0][ResponseKey.Icon.rawValue] as? String else { 
                return nil 
        }
        
        let icon = iconImage(iconString: iconString)
        
        return WeatherItemResult(temperature: temp, icon: icon)
        
    }
    
    private func iconImage(iconString: String) -> UIImage {
        return #imageLiteral(resourceName: "ic_day_clear") //TODO: map this to the icons
    }
}
