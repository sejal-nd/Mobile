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

    static func fetchAlertLanguage(accountNumber: String, completion: @escaping (Result<LanguageResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .fetchAlertLanguage(accountNumber: accountNumber), completion: completion)
    }
    
    static func setAlertLanguage(accountNumber: String, request: AlertLanguageRequest, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .setAlertLanguage(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func fetchAlertBanner(bannerOnly: Bool, stormOnly: Bool, completion: @escaping (Result<[Alert], NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .alertBanner) { (result: Result<AzureAlerts, NetworkingError>) in
            switch result {
            case .success(let data):
                let filteredAlerts: [Alert]
                
                if bannerOnly {
                    filteredAlerts = data.alerts.filter {
                        $0.type == "Global"
                    }
                } else if stormOnly {
                    filteredAlerts = data.alerts.filter {
                        $0.type == "Storm"
                    }
                } else {
                    filteredAlerts = data.alerts.sorted(by: {
                        $0.order < $1.order
                    })
                }
                completion(.success(filteredAlerts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}
