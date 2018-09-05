//
//  MockAlertsService.swift
//  Mobile
//
//  Created by Sam Francis on 11/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class MockAlertsService: AlertsService {
    
    func register(token: String, firstLogin: Bool, completion: @escaping (ServiceResult<Void>) -> Void) {
    }
    
    func fetchAlertPreferences(accountNumber: String, completion: @escaping (ServiceResult<AlertPreferences>) -> Void) {
        let testPrefs = AlertPreferences(outage: true, scheduledMaint: false, severeWeather: true, billReady: false, paymentDue: true, paymentDueDaysBefore: 99, budgetBilling: true, forYourInfo: false)
        completion(.success(testPrefs))
    }
    
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(.success(()))
    }
    
    func enrollBudgetBillingNotification(accountNumber: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(.failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(.success(()))
        }
    }
    
    func fetchAlertLanguage(accountNumber: String, completion: @escaping (ServiceResult<String>) -> Void) {
        completion(.success("English"))
    }
    
    func setAlertLanguage(accountNumber: String, english: Bool, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(.success(()))
    }
    
    func fetchOpcoUpdates(bannerOnly: Bool = false, completion: @escaping (ServiceResult<[OpcoUpdate]>) -> Void) {
        if bannerOnly {
            let opcoUpdates = [OpcoUpdate.from(["Title": "Test Title", "Message": "Test Message"])!]
            completion(.success(opcoUpdates))
        } else {
            completion(.failure(ServiceError(serviceMessage: "Mock Error")))
        }
    }
}
