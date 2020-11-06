//
//  BillService.swift
//  Mobile
//
//  Created by Cody Dillon on 7/24/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

enum BillService {
    static func fetchBudgetBillingInfo(accountNumber: String, completion: @escaping (Result<BudgetBilling, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .budgetBillingInfo(accountNumber: accountNumber), completion: completion)
    }
    
    static func enrollBudgetBilling(accountNumber: String, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .budgetBillingEnroll(accountNumber: accountNumber), completion: completion)
    }
    
    static func unenrollBudgetBilling(accountNumber: String, reason: String, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
        let encodedObject = BudgetBillingUnenrollRequest(reason: reason, comment: "")
        NetworkingLayer.request(router: .budgetBillingUnenroll(accountNumber: accountNumber, encodable: encodedObject), completion: completion)
    }
    
    /// Enroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - accountNumber: The account number to enroll
    ///   - email: Email address to send bills to
    static func enrollPaperlessBilling(accountNumber: String, email: String?, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .paperlessEnroll(accountNumber: accountNumber, request: EmailRequest(email: email)), completion: completion)
    }
    
    /// Unenroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - accountNumber: The account number to unenroll
    static func unenrollPaperlessBilling(accountNumber: String, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .paperlessUnenroll(accountNumber: accountNumber), completion: completion)
    }
    
    /// Get the bill PDF data for display/saving
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - billDate: From account detail endpoint: BillingInfo.billDate
    ///   - documentID: From account detail endpoint: BillingInfo.documentID
    static func fetchBillPdf(accountNumber: String, billDate: Date, documentID: String, completion: @escaping (Result<BillPDF, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .billPDF(accountNumber: accountNumber, date: billDate, documentID: documentID), completion: completion)
    }
    
    static func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date, completion: @escaping (Result<BillingHistoryResult, NetworkingError>) -> ()) {
            
            let startDateString = DateFormatter.yyyyMMddFormatter.string(from: startDate)
            let endDateString = DateFormatter.yyyyMMddFormatter.string(from: endDate)
            
            let encodedObject = BillingHistoryRequest(startDate: startDateString,
                                                      endDate: endDateString,
                                                      statementType: "03",
                                                      billerId: AccountsStore.shared.billerID)
                NetworkingLayer.request(router: .billingHistory(accountNumber: accountNumber, encodable: encodedObject), completion: completion)
        }
}
