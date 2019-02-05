//
//  WeatherItem.swift
//  Mobile
//
//  Created by Samuel Francis on 2/4/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

struct WeatherItem: Mappable {
    let temperature: Int
    let iconName: String
    let accessibilityName: String
    
    init(map: Mapper) throws {
        let periods = try map.from("properties.periods") { json -> [[String: Any]] in
            guard let array = json as? [[String: Any]] else {
                throw MapperError.convertibleError(value: json, type: [[String: Any]].self)
            }
            
            return array
        }
        
        guard let temp = periods.first?["temperature"] as? Int,
        let iconString = periods.first?["icon"] as? String,
        let isDaytime = periods.first?["isDaytime"] as? Bool else {
            throw MapperError.convertibleError(value: map, type: WeatherItem.self)
        }
        
        let forecastData = WeatherItem.forecastData(iconString: iconString, isDaytime: isDaytime)
        
        self.temperature = temp
        self.iconName = forecastData.0
        self.accessibilityName = forecastData.1
    }
    
    private static func forecastData(iconString: String, isDaytime: Bool) -> (String, String) {
        guard let iconName = WeatherIconNames.allCases.first(where: { iconString.contains($0.rawValue) }) else {
            return (WeatherIconNames.unknown.rawValue, "")
        }
        
        switch iconName {
        case .hot, .skc, .windSkc:
            let icon = isDaytime ? "ic_day_clear" : "ic_nt_clear"
            return (icon, NSLocalizedString("Clear", comment: ""))
        case .few, .sct, .windFew, .windSct, .smoke, .haze, .dust:
            let icon = isDaytime ? "ic_day_partlycloudy" : "ic_nt_partlycloudy"
            return (icon, NSLocalizedString("Partly Cloudy", comment: ""))
        case .bkn, .windBkn, .fog:
            let icon = isDaytime ? "ic_day_mostlycloudy" : "ic_nt_mostlycloudy"
            return (icon, NSLocalizedString("Mostly Cloudy", comment: ""))
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
        case .unknown:
            return (WeatherIconNames.unknown.rawValue, "")
        }
    }
}

enum WeatherIconNames: String, CaseIterable {
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
