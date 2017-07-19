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

//added greeting to this so everything loads at the same time
struct WeatherItemResult {
    let temperature: Int
    let icon: UIImage
}

private enum ResponseKey : String {
    case Properties = "properties"
    case Periods = "periods"
    case Temperature = "temperature"
    case Icon = "icon"
}

private enum weatherIcons: String { 
    case HOT = "hot"
    case COLD = "cold"
    case TS_WARN = "ts_warn"
    case TS_WATCH = "ts_watch"
    case TS_HURR_WARN = "ts_hurr_warn" 
    case HURR_WARN = "hurr_warn" 
    case HURR_WATCH = "hurr_watch"
    case FOG = "fog"
    case HAZE = "haze"
    case SMOKE = "smoke"
    case DUST = "dust"
    case SKC = "skc"
    case WIND_SKC = "wind_skc"
    case BKN = "bkn"
    case WIND_BKN = "wind_bkn"
    case FEW = "few"
    case SCT = "sct"
    case WIND_FEW = "wind_few"
    case WIND_SCT = "wind_sct"
    case TORNADO = "tornado"
    case RAIN = "rain"
    case RAIN_SHOWERS = "rain_showers"
    case RAIN_SHOWERS_HI = "rain_showers_hi"
    case RAIN_SLEET = "rain_sleet"
    case RAIN_FZRA = "rain_fzra"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
    case TORNADO = "tornado"
}

struct WeatherAPI: WeatherService { 
    
    func getWeather(address: String, completion: @escaping (_ result: ServiceResult<WeatherItemResult>) -> Swift.Void) {
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
                            let results = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                            guard let resultDictionary = results,
                                let weatherItemResult = self.weatherItemFrom(data: resultDictionary) else {
                                    let serviceError = ServiceError(serviceCode: ServiceErrorCode.Parsing.rawValue, cause: error)
                                    completion(ServiceResult.Failure(serviceError))
                                    return
                            }
                            
                            completion(ServiceResult.Success(weatherItemResult))
                            
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
            let temp = periods[0][ResponseKey.Temperature.rawValue] as? Int,
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
