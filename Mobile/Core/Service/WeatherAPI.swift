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
    case IsDaytime = "isDaytime"
}

//TODO: when swift is refactorable make this more readable 
private enum WeatherIconNames: String { 
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
}

extension WeatherIconNames {
    static let values = [HOT, COLD, TS_WARN, TS_WATCH, TS_HURR_WARN, HURR_WARN, HURR_WATCH, FOG, HAZE, SMOKE, DUST, SKC, WIND_SKC, BKN, WIND_BKN, FEW, SCT, TORNADO, RAIN, RAIN_SHOWERS, RAIN_SHOWERS_HI, RAIN_SLEET, RAIN_FZRA, SNOW_SLEET, FZRA, RAIN_SNOW, SNOW_FZRA, SLEET, TSRA, TSRA_SCT, TSRA_HI, OVC, WIND_OVC, SNOW, BLIZZARD]
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
            let iconString = periods[0][ResponseKey.Icon.rawValue] as? String,
            let isDaytime = periods[0][ResponseKey.IsDaytime.rawValue] as? Bool else { 
                return nil 
        }
        
        let icon = iconImage(iconString: iconString, isDaytime: isDaytime)
        
        return WeatherItemResult(temperature: temp, icon: icon)
        
    }
    
    private func iconImage(iconString: String, isDaytime: Bool) -> UIImage {
        
        let iconName = WeatherIconNames.values.filter { iconString.contains($0.rawValue) }.first
        
        if let iconName = iconName {
            switch iconName.rawValue {
            case WeatherIconNames.HOT.rawValue:
                return #imageLiteral(resourceName: "ic_hot")
            case WeatherIconNames.COLD.rawValue:
                return #imageLiteral(resourceName: "ic_cold")
            case WeatherIconNames.TS_WARN.rawValue:
                return #imageLiteral(resourceName: "ic_tropicalstorm")
            case WeatherIconNames.TS_WATCH.rawValue:
                return #imageLiteral(resourceName: "ic_tropicalstorm")
            case WeatherIconNames.TS_HURR_WARN.rawValue:
                return #imageLiteral(resourceName: "ic_tropicalstorm")
            case WeatherIconNames.HURR_WARN.rawValue:
                return #imageLiteral(resourceName: "ic_hurricane")
            case WeatherIconNames.HURR_WATCH.rawValue:
                return #imageLiteral(resourceName: "ic_hurricane")
            case WeatherIconNames.FOG.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_fog")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_fog")
                }
            case WeatherIconNames.HAZE.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_fog")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_fog")
                }
            case WeatherIconNames.SMOKE.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_fog")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_fog")
                }
            case WeatherIconNames.DUST.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_fog")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_fog")
                }
            case WeatherIconNames.SKC.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_clear")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_clear")
                }
            case WeatherIconNames.WIND_SKC.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_clear")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_clear")
                }
            case WeatherIconNames.BKN.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_mostlycloudy")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_mostlycloudy")
                }
            case WeatherIconNames.WIND_BKN.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_mostlycloudy")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_mostlycloudy")
                }
            case WeatherIconNames.FEW.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_partlycloudy")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_partlycloudy")
                }
            case WeatherIconNames.SCT.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_partlycloudy")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_partlycloudy")
                }
            case WeatherIconNames.WIND_FEW.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_partlycloudy")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_partlycloudy")
                }
            case WeatherIconNames.WIND_SCT.rawValue:
                if isDaytime {
                    return #imageLiteral(resourceName: "ic_day_partlycloudy")
                } else {
                    return #imageLiteral(resourceName: "ic_nt_partlycloudy")
                }
            case WeatherIconNames.TORNADO.rawValue:
                return #imageLiteral(resourceName: "ic_tornado")
            case WeatherIconNames.RAIN.rawValue:
                return #imageLiteral(resourceName: "ic_rain")
            case WeatherIconNames.RAIN_SHOWERS.rawValue:
                return #imageLiteral(resourceName: "ic_rain")
            case WeatherIconNames.RAIN_SHOWERS_HI.rawValue:
                return #imageLiteral(resourceName: "ic_rain")
            case WeatherIconNames.RAIN_SLEET.rawValue:
                return #imageLiteral(resourceName: "ic_rain")
            case WeatherIconNames.RAIN_FZRA.rawValue:
                return #imageLiteral(resourceName: "ic_rain")
            case WeatherIconNames.SNOW_SLEET.rawValue:
                return #imageLiteral(resourceName: "ic_sleet")
            case WeatherIconNames.FZRA.rawValue:
                return #imageLiteral(resourceName: "ic_sleet")
            case WeatherIconNames.RAIN_SNOW.rawValue:
                return #imageLiteral(resourceName: "ic_sleet")
            case WeatherIconNames.SNOW_FZRA.rawValue:
                return #imageLiteral(resourceName: "ic_sleet")
            case WeatherIconNames.SLEET.rawValue:
                return #imageLiteral(resourceName: "ic_sleet")
            case WeatherIconNames.TSRA.rawValue:
                return #imageLiteral(resourceName: "ic_tstorms")
            case WeatherIconNames.TSRA_SCT.rawValue:
                return #imageLiteral(resourceName: "ic_tstorms")
            case WeatherIconNames.TSRA_HI.rawValue:
                return #imageLiteral(resourceName: "ic_tstorms")
            case WeatherIconNames.OVC.rawValue:
                return #imageLiteral(resourceName: "ic_cloudy")
            case WeatherIconNames.WIND_OVC.rawValue:
                return #imageLiteral(resourceName: "ic_cloudy")
            case WeatherIconNames.SNOW.rawValue:
                return #imageLiteral(resourceName: "ic_snow")
            case WeatherIconNames.BLIZZARD.rawValue:
                return #imageLiteral(resourceName: "ic_snow")
            default:
                return UIImage()
            }
        }
        return UIImage()
    }
}
