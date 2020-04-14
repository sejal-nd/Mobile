//
//  WeatherService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/27/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherServiceNew {
    static func getWeather(completion: @escaping (Result<NewWeather, Error>) -> ()) {
        let locationManager = CLLocationManager()
        
        // Should be moved in prod version to when homescreen appreas
        locationManager.requestWhenInUseAuthorization()
        
        guard (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways),
            let currentLocation = locationManager.location else {
                print("No Location permissions")
                // todo FAILURE BLOCK
                return
        }
           
        let lat = String(format: "%.3f", currentLocation.coordinate.latitude)
        let long = String(format: "%.3f", currentLocation.coordinate.longitude)
        print("123123123")
           print(lat)
        print(long)
        
        //lat: "39.295", long: "-76.624")
        ServiceLayer.request(router: .weather(lat: lat, long: long)) { (result: Result<NewWeather, NetworkingError>) in
            switch result {
            case .success(let weather):
                print("NetworkTest 9 SUCCESS: \(weather) BREAK \(weather.temperature)")
                completion(.success(weather))
            case .failure(let error):
                print("NetworkTest 9 FAIL: \(error)")
            }
        }
    }
}

