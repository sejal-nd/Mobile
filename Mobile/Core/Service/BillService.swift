//
//  BillService.swift
//  Mobile
//
//  Created by Marc Shilling on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol BillService {
    /// Fetch infomation about the user's budget billing enrollment
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain a BudgetBillingInfo 
    ////    object upon success, or the error on failure.
    func fetchBudgetBillingInfo(accountNumber: String) -> Observable<BudgetBillingInfo>
    
    /// Enroll the user in budget billing
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - completion: the completion block to execute upon completion.
    func enrollBudgetBilling(accountNumber: String) -> Observable<Void>
    
    /// Unenroll the user in budget billing
    ///
    /// - Parameters:
    ///   - accountNumber: The account to unenroll
    ///   - reason: The reason the user said they are unenrolling
    ///   - completion: the completion block to execute upon completion.
    func unenrollBudgetBilling(accountNumber: String, reason: String) -> Observable<Void>
    

    /// Enroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - accountNumber: The account number to enroll
    ///   - email: Email address to send bills to
    ///   - completion: the completion block to execute upon completion.
    func enrollPaperlessBilling(accountNumber: String, email: String?) -> Observable<Void>
    
    /// Unenroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - accountNumber: The account number to unenroll
    ///   - completion: the completion block to execute upon completion.
    func unenrollPaperlessBilling(accountNumber: String) -> Observable<Void>
    
    /// Get the bill PDF data for display/saving
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - billDate: From account detail endpoint: BillingInfo.billDate
    ///   - completion: the completion block to execute upon completion.
    func fetchBillPdf(accountNumber: String, billDate: Date) -> Observable<String>
    
    /// Get the BillingHistoryItems for display
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - startDate: the start date of the desired history
    ///   - endDate: the end date of the desired history
    ///   - completion: the completion block to execute upon completion.
    func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) -> Observable<BillingHistory>
}
