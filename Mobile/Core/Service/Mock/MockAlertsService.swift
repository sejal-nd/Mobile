//
//  MockAlertsService.swift
//  Mobile
//
//  Created by Sam Francis on 11/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class MockAlertsService: AlertsService {
    
    func register(token: String, firstLogin: Bool) -> Observable<Void> {
        return .just(())
    }
    
    func fetchAlertPreferences(accountNumber: String) -> Observable<AlertPreferences> {
        let dataFile = MockJSONManager.File.alertPreferences
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.jsonObject(fromFile: dataFile, key: key)
            .map { json in
                guard let jsonArray = json["alertPreferences"] as? NSArray,
                    let prefsArray = AlertPreference.from(jsonArray) else {
                    throw ServiceError.parsing
                }
                
                return AlertPreferences(alertPreferences: prefsArray)
        }
    }
    
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences) -> Observable<Void> {
        return .just(())
    }
    
    func enrollBudgetBillingNotification(accountNumber: String) -> Observable<Void> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        } else {
            return .just(())
        }
    }
    
    func fetchAlertLanguage(accountNumber: String) -> Observable<String> {
        return .just("English")
    }
    
    func setAlertLanguage(accountNumber: String, english: Bool) -> Observable<Void> {
        return .just(())
    }
    
    func fetchOpcoUpdates(bannerOnly: Bool = false, stormOnly: Bool = false) -> Observable<[OpcoUpdate]> {
        let dataFile = MockJSONManager.File.opcoUpdates
        let key = MockAppState.current.opCoUpdatesKey
        return MockJSONManager.shared.rx.mappableArray(fromFile: dataFile, key: key)
    }
}
