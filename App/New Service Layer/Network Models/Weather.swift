//
//  NewWeather.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct Weather: Decodable {
    public var temperature: Int?
    public var iconName: String
    public let accessibilityName: String
    
    public init(from decoder: Decoder) throws {
        let rawResponse = try RawServerResponse(from: decoder)
        
        self.temperature = rawResponse.properties.periods.first?.temperature
        let isDaytime = rawResponse.properties.periods.first?.isDaytime ?? false
        let iconString = rawResponse.properties.periods.first?.iconName ?? ""
        
        let forecastData = Weather.forecastData(iconString: iconString, isDaytime: isDaytime)
        
        self.iconName = forecastData.0
        self.accessibilityName = forecastData.1
    }
}

fileprivate struct RawServerResponse: Decodable {
    var properties: Properties
    
    struct Properties: Decodable {
        var periods:  [Periods]
    }
    
    struct Periods: Decodable {
        var temperature: Int?
        var isDaytime: Bool?
        public var iconName: String?
        
        
        enum CodingKeys: String, CodingKey {
            case temperature
            case isDaytime
            case iconName = "icon"
        }
    }
}

// MARK: - Legacy Logic

extension Weather {
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



//
//"properties": {
//"updated": "2020-03-27T02:33:54+00:00",
//"units": "us",
//"forecastGenerator": "HourlyForecastGenerator",
//"generatedAt": "2020-03-27T14:49:43+00:00",
//"updateTime": "2020-03-27T02:33:54+00:00",
//"validTimes": "2020-03-26T20:00:00+00:00/P7DT5H",
//"elevation": {
//    "value": 39.014400000000002,
//    "unitCode": "unit:m"
//},
//"periods": [
//    {
//        "number": 1,
//        "name": "",
//        "startTime": "2020-03-27T10:00:00-04:00",
//        "endTime": "2020-03-27T11:00:00-04:00",
//        "isDaytime": true,
//        "temperature": 57,
//        "temperatureUnit": "F",
//        "temperatureTrend": null,
//        "windSpeed": "6 mph",
//        "windDirection": "NW",
//        "icon": "https://api.weather.gov/icons/land/day/rain_showers,20?size=small",
//        "shortForecast": "Slight Chance Rain Showers",
//        "detailedForecast": ""
//    }
