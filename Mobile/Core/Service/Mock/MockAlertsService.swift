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
        completion(.Success(testPrefs))
    }
    
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(.Success(()))
    }
    
    func enrollBudgetBillingNotification(accountNumber: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(ServiceResult.Success(()))
        }
    }
    
    func fetchAlertLanguage(accountNumber: String, completion: @escaping (ServiceResult<String>) -> Void) {
        completion(.Success("English"))
    }
    
    func setAlertLanguage(accountNumber: String, english: Bool, completion: @escaping (ServiceResult<Void>) -> Void) {
        completion(.Success(()))
    }
    
    func fetchOpcoUpdates(accountDetail: AccountDetail, completion: @escaping (ServiceResult<[OpcoUpdate]>) -> Void) {
        if accountDetail.accountNumber == "1234567890" {
            let opcoUpdates = [OpcoUpdate.from(["Title": "Test Title", "Message": "Test Message"])!]
            completion(ServiceResult.Success(opcoUpdates))
        } else {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        }
    }
}
