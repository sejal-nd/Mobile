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
        let testPrefs = AlertPreferences(outage: true,
                                         scheduledMaint: false,
                                         severeWeather: true,
                                         billReady: false,
                                         paymentDue: true,
                                         paymentDueDaysBefore: 99,
                                         paymentPosted: true,
                                         paymentPastDue: true,
                                         budgetBilling: true,
                                         appointmentTracking: false,
                                         forYourInfo: false)
        return .just(testPrefs)
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
    
    var updatesShouldSucceed = true
    
    func fetchOpcoUpdates(bannerOnly: Bool = false, stormOnly: Bool = false) -> Observable<[OpcoUpdate]> {
        if updatesShouldSucceed {
            let opcoUpdates = [OpcoUpdate.from(["Title": "Test Title", "Message": "Test Message"])!]
            return .just(opcoUpdates)
        } else {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        }
    }
}
