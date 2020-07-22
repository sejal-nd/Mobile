//
//  MockBillService.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MockBillService: BillService {
    /// Get the BillingHistoryItems for display
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - startDate: the start date of the desired history
    ///   - endDate: the end date of the desired history
    func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) -> Observable<BillingHistory> {
        let dataFile = MockJSONManager.File.billingHistory
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }


    func fetchBudgetBillingInfo(accountNumber: String) -> Observable<BudgetBillingInfo> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        }
        
        let dataFile = MockJSONManager.File.budgetBillingInfo
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.mappableObject(fromFile: dataFile, key: key)
    }

    func enrollBudgetBilling(accountNumber: String) -> Observable<Void> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        } else {
            return .just(())
        }
    }
    
    func unenrollBudgetBilling(accountNumber: String, reason: String) -> Observable<Void> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        } else {
            return .just(())
        }
    }

    func enrollPaperlessBilling(accountNumber: String, email: String?) -> Observable<Void> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        } else {
            return .just(())
        }
    }
    
    func unenrollPaperlessBilling(accountNumber: String) -> Observable<Void> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        } else {
            return .just(())
        }
    }
    
    func fetchBillPdf(accountNumber: String, billDate: Date, documentID: String) -> Observable<String> {
        let dataFile = MockJSONManager.File.billPdf
        let key = MockUser.current.currentAccount.dataKey(forFile: dataFile)
        return MockJSONManager.shared.rx.jsonObject(fromFile: dataFile, key: key)
            .map { json in
                guard let pdfString = json["billImageData"] as? String else {
                    throw ServiceError(serviceMessage: "Mock Error")
                }
                
                return pdfString
        }
    }
}
