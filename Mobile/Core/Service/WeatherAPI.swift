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
import Mapper

let baseUrl = "https://api.weather.gov/"

//added greeting to this so everything loads at the same time
struct WeatherItem {
    let temperature: Int
    let iconName: String
    let shortForecast: String
    
    init?(json: [String: Any]) {
        guard let properties = json["properties"] as? Dictionary<String, Any>,
            let periods = properties["periods"] as? Array<[String: Any]>,
            let temp = periods[0]["temperature"] as? Int,
            let iconString = periods[0]["icon"] as? String,
            let isDaytime = periods[0]["isDaytime"] as? Bool,
            let shortForecast = periods[0]["shortForecast"] as? String else {
                return nil
        }
        
        let iconNameString = WeatherItem.iconName(iconString: iconString, isDaytime: isDaytime)
        
        self.temperature = temp
        self.iconName = iconNameString
        self.shortForecast = shortForecast
    }
    
    private static func iconName(iconString: String, isDaytime: Bool) -> String {
        
        if let iconName = WeatherIconNames.values.first(where: { iconString.contains($0.rawValue) }) {
            switch iconName {
            case .HOT, .SKC, .WIND_SKC:
                if isDaytime {
                    return "ic_day_clear"
                } else {
                    return "ic_nt_clear"
                }
            case .FEW, .SCT, .WIND_FEW, .WIND_SCT, .SMOKE, .HAZE, .DUST:
                if isDaytime {
                    return "ic_day_partlycloudy"
                } else {
                    return "ic_nt_partlycloudy"
                }
            case .BKN, .WIND_BKN, .FOG:
                if isDaytime {
                    return "ic_day_mostlycloudy"
                } else {
                    return "ic_nt_mostlycloudy"
                }
            case .RAIN, .RAIN_SHOWERS, .RAIN_SLEET, .RAIN_SHOWERS_HI, .RAIN_FZRA:
                return "ic_rain"
            case .SNOW_SLEET, .FZRA, .RAIN_SNOW, .SNOW_FZRA, .SLEET:
                return "ic_sleet"
            case .TSRA, .TSRA_SCT, .TSRA_HI, .TS_HURR_WARN, .TS_WARN, .TS_WATCH, .HURR_WARN, .HURR_WATCH, .TORNADO:
                return "ic_tstorms"
            case .OVC, .WIND_OVC:
                return "ic_cloudy"
            case .SNOW, .BLIZZARD, .COLD:
                return "ic_snow"
            default:
                return WeatherIconNames.UNKNOWN.rawValue
            }
        }
        return WeatherIconNames.UNKNOWN.rawValue
    }
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
                            guard let json = results,
                                let weatherItem = WeatherItem(json: json) else {
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
    
}
