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
        return .just(BillingHistory.from(["billing_and_payment_history": []])!)
    }


    func fetchBudgetBillingInfo(accountNumber: String) -> Observable<BudgetBillingInfo> {
        if accountNumber == "0000" {
            return .error(ServiceError(serviceMessage: "Mock Error"))
        } else {
            let info = BudgetBillingInfo.from(["enrolled": true, "averageMonthlyBill": 120])!
            return .just(info)
        }
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
    
    func fetchBillPdf(accountNumber: String, billDate: Date) -> Observable<String> {
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
