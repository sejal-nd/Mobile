//
//  AlertSrevice.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/5/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum AlertService {
    static func register(request: AlertRegistrationRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .registerForAlerts(request: request), completion: completion)
    }
    
    static func fetchAlertPreferences(accountNumber: String, completion: @escaping (Result<AlertPreferences, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .alertPreferencesLoad(accountNumber: accountNumber), completion: completion)
    }
    
    static func setAlertPreferences(accountNumber: String, request: AlertPreferencesRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .alertPreferencesUpdate(accountNumber: accountNumber, request: request), completion: completion)
    }

    static func fetchAlertLanguage(accountNumber: String, completion: @escaping (Result<String, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .fetchAlertLanguage(accountNumber: accountNumber), completion: completion)
    }
    
    static func setAlertLanguage(accountNumber: String, request: AlertLanguageRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .setAlertLanguage(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func fetchAlertBanner(bannerOnly: Bool, stormOnly: Bool, completion: @escaping (Result<[Alert], NetworkingError>) -> ()) {
        var filterString: String

        if bannerOnly {
            filterString = "(Enable eq 1) and (CustomerType eq 'Banner')"
        } else if stormOnly {
            filterString = "(Enable eq 1) and (CustomerType eq 'Storm')"
        } else {
            filterString = "(Enable eq 1) and ((CustomerType eq 'All')"
            ["Banner", "PeakRewards", "Peak Time Savings", "Smart Energy Rewards", "Storm"]
                .forEach {
                    filterString += "or (CustomerType eq '\($0)')"
            }
            filterString += ")"
        }
        
        let queryItem = URLQueryItem(name: "$filter", value: filterString)
        
        NetworkingLayer.request(router: .alertBanner(additionalQueryItem: queryItem)) { (result: Result<SharePointAlert, NetworkingError>) in
            switch result {
            case .success(let data):
                completion(.success(data.alerts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}
