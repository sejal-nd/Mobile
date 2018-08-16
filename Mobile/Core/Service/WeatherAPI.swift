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
    let accessibilityName: String
    
    init?(json: [String: Any]) {
        guard let properties = json["properties"] as? Dictionary<String, Any>,
            let periods = properties["periods"] as? Array<[String: Any]>,
            let temp = periods[0]["temperature"] as? Int,
            let iconString = periods[0]["icon"] as? String,
            let isDaytime = periods[0]["isDaytime"] as? Bool else {
                return nil
        }
        
        let forecastData = WeatherItem.forecastData(iconString: iconString, isDaytime: isDaytime)
        
        self.temperature = temp
        self.iconName = forecastData.0
        self.accessibilityName = forecastData.1
    }
    
    private static func forecastData(iconString: String, isDaytime: Bool) -> (String, String) {
        
        if let iconName = WeatherIconNames.values.first(where: { iconString.contains($0.rawValue) }) {
            switch iconName {
            case .hot, .skc, .windSkc:
                if isDaytime {
                    return ("ic_day_clear", NSLocalizedString("Clear", comment: ""))
                } else {
                    return ("ic_nt_clear", NSLocalizedString("Clear", comment: ""))
                }
            case .few, .sct, .windFew, .windSct, .smoke, .haze, .dust:
                if isDaytime {
                    return ("ic_day_partlycloudy", NSLocalizedString("Partly Cloudy", comment: ""))
                } else {
                    return ("ic_nt_partlycloudy", NSLocalizedString("Partly Cloudy", comment: ""))
                }
            case .bkn, .windBkn, .fog:
                if isDaytime {
                    return ("ic_day_mostlycloudy", NSLocalizedString("Mostly Cloudy", comment: ""))
                } else {
                    return ("ic_nt_mostlycloudy", NSLocalizedString("Mostly Cloudy", comment: ""))
                }
            case .rain, .rainShowers, .rainSleet, .rainShowersHi, .rainFzra:
                return ("ic_rain", NSLocalizedString("Rain", comment: ""))
            case .snowSleet, .fzra, .rainSnow, .snowFzra, .sleet:
                return ("ic_sleet", NSLocalizedString("Sleet", comment: ""))
            case .tsra, .tsraSct, .tsraHi, .tsHurrWarn, .tsWarn, .tsWatch, .hurrWarn, .hurrWatch, .tornado:
                return ("ic_tstorms", NSLocalizedString("Thunderstorm", comment: ""))
            case .ovc, .windOvc:
                return ("ic_cloudy", NSLocalizedString("Overcast", comment: ""))
            case .snow, .blizzard, .cold:
                return ("ic_snow", NSLocalizedString("Snow", comment: ""))
            default:
                return (WeatherIconNames.unknown.rawValue, "")
            }
        }
        return (WeatherIconNames.unknown.rawValue, "")
    }
}


//TODO: when swift is refactorable make this more readable 
enum WeatherIconNames: String { 
    case hot = "hot"
    case cold = "cold"
    case tsWarn = "ts_warn"
    case tsWatch = "ts_watch"
    case tsHurrWarn = "ts_hurr_warn"
    case hurrWarn = "hurr_warn"
    case hurrWatch = "hurr_watch"
    case fog = "fog"
    case haze = "haze"
    case smoke = "smoke"
    case dust = "dust"
    case skc = "skc"
    case windSkc = "wind_skc"
    case bkn = "bkn"
    case windBkn = "wind_bkn"
    case few = "few"
    case sct = "sct"
    case windFew = "wind_few"
    case windSct = "wind_sct"
    case tornado = "tornado"
    case rain = "rain"
    case rainShowers = "rain_showers"
    case rainShowersHi = "rain_showers_hi"
    case rainSleet = "rain_sleet"
    case rainFzra = "rain_fzra"
    case snowSleet = "snow_sleet"
    case fzra = "fzra"
    case rainSnow = "rain_snow"
    case snowFzra = "snow_fzra"
    case sleet = "sleet"
    case tsra = "tsra"
    case tsraSct = "tsra_sct"
    case tsraHi = "tsra_hi"
    case ovc = "ovc"
    case windOvc = "wind_ovc"
    case snow = "snow"
    case blizzard = "blizzard"
    case unknown = "unknown"
}

extension WeatherIconNames {
    static let values = [hot, cold, tsWarn, tsWatch, tsHurrWarn, hurrWarn, hurrWatch, fog, haze, smoke, dust, skc, windSkc, bkn, windBkn, few, sct, tornado, rain, rainShowers, rainShowersHi, rainSleet, rainFzra, snowSleet, fzra, rainSnow, snowFzra, sleet, tsra, tsraSct, tsraHi, ovc, windOvc, snow, blizzard]
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
                        let serviceError = ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: error)
                        completion(ServiceResult.failure(serviceError))
                        
                    } else {
//                        let responseString = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
//                        dLog(responseString)
                        
                        do {
                            let results = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                            guard let json = results,
                                let weatherItem = WeatherItem(json: json) else {
                                    let serviceError = ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue, cause: error)
                                    completion(ServiceResult.failure(serviceError))
                                    return
                            }
                            completion(ServiceResult.success(weatherItem))
                            
                        }
                        catch let error as NSError {
                            let serviceError = ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue, cause: error)
                            completion(ServiceResult.failure(serviceError))
                        }
                    }
                }).resume()
                
            } else {
                let serviceError = ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: error)
                completion(ServiceResult.failure(serviceError))
            }
        })
    }
    
    private func urlString(coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.3f", coordinate.latitude)
        let lon = String(format: "%.3f", coordinate.longitude)
        return baseUrl + "points/\(lat),\(lon)/forecast/hourly"
        
    }
    
}
