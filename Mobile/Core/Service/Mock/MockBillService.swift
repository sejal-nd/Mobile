//
//  MockBillService.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockBillService: BillService {
    /// Get the BillingHistoryItems for display
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - startDate: the start date of the desired history
    ///   - endDate: the end date of the desired history
    ///   - completion: the completion block to execute upon completion.
    func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date, completion: @escaping (ServiceResult<BillingHistory>) -> Void) {
        completion(ServiceResult.Success(BillingHistory.from(["billing_and_payment_history": []])!))
    }


    func fetchBudgetBillingInfo(accountNumber: String, completion: @escaping (_ result: ServiceResult<BudgetBillingInfo>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            let info = BudgetBillingInfo.from(["enrolled": true, "averageMonthlyBill": 120])!
            completion(ServiceResult.Success(info))
        }
    }

    func enrollBudgetBilling(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(ServiceResult.Success(()))
        }
    }
    
    func unenrollBudgetBilling(accountNumber: String, reason: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(ServiceResult.Success(()))
        }
    }

    func enrollPaperlessBilling(accountNumber: String, email: String?, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(ServiceResult.Success(()))
        }
    }
    
    func unenrollPaperlessBilling(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        if accountNumber == "0000" {
            completion(ServiceResult.Failure(ServiceError(serviceMessage: "Mock Error")))
        } else {
            completion(ServiceResult.Success(()))
        }
    }
    
    func fetchBillPdf(accountNumber: String, billDate: Date, completion: @escaping (_ result: ServiceResult<String>) -> Void) {
        
    }
}
