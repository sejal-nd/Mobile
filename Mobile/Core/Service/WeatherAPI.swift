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
struct WeatherItem {
    let temperature: Int
    let iconName: String
}

private enum ResponseKey : String {
    case Properties = "properties"
    case Periods = "periods"
    case Temperature = "temperature"
    case Icon = "icon"
    case IsDaytime = "isDaytime"
}

//TODO: when swift is refactorable make this more readable 
enum WeatherIconNames: String { 
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
    case SNOW_SLEET = "snow_sleet"
    case FZRA = "fzra"
    case RAIN_SNOW = "rain_snow"
    case SNOW_FZRA = "snow_fzra"
    case SLEET = "sleet"
    case TSRA = "tsra"
    case TSRA_SCT = "tsra_sct"
    case TSRA_HI = "tsra_hi"
    case OVC = "ovc"
    case WIND_OVC = "wind_ovc"
    case SNOW = "snow"
    case BLIZZARD = "blizzard"
    case UNKNOWN = "unknown"
}

extension WeatherIconNames {
    static let values = [HOT, COLD, TS_WARN, TS_WATCH, TS_HURR_WARN, HURR_WARN, HURR_WATCH, FOG, HAZE, SMOKE, DUST, SKC, WIND_SKC, BKN, WIND_BKN, FEW, SCT, TORNADO, RAIN, RAIN_SHOWERS, RAIN_SHOWERS_HI, RAIN_SLEET, RAIN_FZRA, SNOW_SLEET, FZRA, RAIN_SNOW, SNOW_FZRA, SLEET, TSRA, TSRA_SCT, TSRA_HI, OVC, WIND_OVC, SNOW, BLIZZARD]
}
struct WeatherAPI: WeatherService { 
    
    func getWeather(address: String, completion: @escaping (_ result: ServiceResult<WeatherItem>) -> Swift.Void) {
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
                                let weatherItem = self.weatherItemFrom(data: resultDictionary) else {
                                    let serviceError = ServiceError(serviceCode: ServiceErrorCode.Parsing.rawValue, cause: error)
                                    completion(ServiceResult.Failure(serviceError))
                                    return
                            }
                            
                            completion(ServiceResult.Success(weatherItem))
                            
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
    
    private func weatherItemFrom(data: Dictionary<String, Any?>?) -> WeatherItem? {
        guard let properties = data?[ResponseKey.Properties.rawValue] as? Dictionary<String, Any>,
            let periods = properties[ResponseKey.Periods.rawValue] as? Array<[String: Any]>,
            let temp = periods[0][ResponseKey.Temperature.rawValue] as? Int,
            let iconString = periods[0][ResponseKey.Icon.rawValue] as? String,
            let isDaytime = periods[0][ResponseKey.IsDaytime.rawValue] as? Bool else { 
                return nil 
        }
        
        let iconNameString = iconName(iconString: iconString, isDaytime: isDaytime)
        
        return WeatherItem(temperature: temp, iconName: iconNameString)
        
    }
    
    private func iconName(iconString: String, isDaytime: Bool) -> String {
        
        let iconName = WeatherIconNames.values.filter { iconString.contains($0.rawValue) }.first
        
        if let iconName = iconName {
            switch iconName.rawValue {
            case WeatherIconNames.HOT.rawValue, WeatherIconNames.SKC.rawValue, WeatherIconNames.WIND_SKC.rawValue:
                if isDaytime {
                    return "ic_day_clear"
                } else {
                    return "ic_nt_clear"
                }
            case WeatherIconNames.FEW.rawValue, WeatherIconNames.SCT.rawValue, WeatherIconNames.WIND_FEW.rawValue,
                 WeatherIconNames.WIND_SCT.rawValue, WeatherIconNames.SMOKE.rawValue, WeatherIconNames.HAZE.rawValue,
                 WeatherIconNames.DUST.rawValue:
                if isDaytime {
                    return "ic_day_partlycloudy"
                } else {
                    return "ic_nt_partlycloudy"
                }
            case WeatherIconNames.BKN.rawValue, WeatherIconNames.WIND_BKN.rawValue, WeatherIconNames.FOG.rawValue:
                if isDaytime {
                    return "ic_day_mostlycloudy"
                } else {
                    return "ic_nt_mostlycloudy"
                }
            case WeatherIconNames.RAIN.rawValue, WeatherIconNames.RAIN_SHOWERS.rawValue, WeatherIconNames.RAIN_SLEET.rawValue,
                 WeatherIconNames.RAIN_SHOWERS_HI.rawValue, WeatherIconNames.RAIN_FZRA.rawValue:
                return "ic_rain"
            case WeatherIconNames.SNOW_SLEET.rawValue, WeatherIconNames.FZRA.rawValue, WeatherIconNames.RAIN_SNOW.rawValue,
                 WeatherIconNames.SNOW_FZRA.rawValue, WeatherIconNames.SLEET.rawValue:
                return "ic_sleet"
            case WeatherIconNames.TSRA.rawValue, WeatherIconNames.TSRA_SCT.rawValue, WeatherIconNames.TSRA_HI.rawValue,
                 WeatherIconNames.TS_HURR_WARN.rawValue, WeatherIconNames.TS_WARN.rawValue, WeatherIconNames.TS_WATCH.rawValue,
                 WeatherIconNames.TS_HURR_WARN.rawValue, WeatherIconNames.HURR_WARN.rawValue, WeatherIconNames.HURR_WATCH.rawValue,
                 WeatherIconNames.TORNADO.rawValue:
                return "ic_tstorms"
            case WeatherIconNames.OVC.rawValue, WeatherIconNames.WIND_OVC.rawValue:
                return "ic_cloudy"
            case WeatherIconNames.SNOW.rawValue, WeatherIconNames.BLIZZARD.rawValue, WeatherIconNames.COLD.rawValue:
                return "ic_snow"
            default:
                return WeatherIconNames.UNKNOWN.rawValue
            }
        }
        return WeatherIconNames.UNKNOWN.rawValue
    }
}
