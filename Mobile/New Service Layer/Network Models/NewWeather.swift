//
//  NewWeather.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewWeather: Decodable {
    public var temperature: String?
    public var unit: String
    public var isDaytime: Bool?
    public var shortForecast: String?
    
    public init(from decoder: Decoder) throws {
        let rawResponse = try RawServerResponse(from: decoder)
        
        
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let propertiesContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
//                                                                forKey: .properties)
//
//        // how to parse this json array for first element only?....
//        let periodsContainer = try propertiesContainer.nestedContainer(keyedBy: CodingKeys.self,
//                                                                       forKey: .periods)
        
        
        self.temperature = rawResponse.properties.periods.first?.temperature
        self.unit = rawResponse.properties.periods.first?.unit ?? "F"
        self.isDaytime = rawResponse.properties.periods.first?.isDaytime
        self.shortForecast = rawResponse.properties.periods.first?.shortForecast
    }
}

fileprivate struct RawServerResponse: Decodable {
    var properties: Properties
    
    struct Properties: Decodable {
        var periods:  [Periods]
    }
    
    struct Periods: Decodable {
        var temperature: String?
        var unit: String = "F"
        var isDaytime: Bool?
        var shortForecast: String?
    }
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
