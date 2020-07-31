//
//  WeatherService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherService {
    static func getWeather(address: String, completion: @escaping (Result<Weather, NetworkingError>) -> ()) {
        let reverseGeocoder = CLGeocoder()
        
        reverseGeocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let placemarks = placemarks,
                !placemarks.isEmpty,
                let coordinate = placemarks.first?.location?.coordinate else {
                    completion(.failure(.reverseGeocodeFailure))
                    return
            }
            
            let lat = String(format: "%.3f", coordinate.latitude)
            let long = String(format: "%.3f", coordinate.longitude)
            NetworkingLayer.request(router: .weather(lat: lat, long: long), completion: completion)
        }
    }
}
