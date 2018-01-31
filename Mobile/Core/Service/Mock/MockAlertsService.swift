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
    }
    
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func enrollBudgetBillingNotification(accountNumber: String, completion: @escaping (ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(ServiceResult.Success(()))
        }
    }
    
    func fetchAlertLanguage(accountNumber: String, completion: @escaping (ServiceResult<String>) -> Void) {
        
    }
    
    func setAlertLanguage(accountNumber: String, english: Bool, completion: @escaping (ServiceResult<Void>) -> Void) {
        
    }
    
    func fetchOpcoUpdates(accountDetail: AccountDetail, completion: @escaping (ServiceResult<[OpcoUpdate]>) -> Void) {
        
    }
}
