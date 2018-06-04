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
    func fetchBudgetBillingInfo(accountNumber: String, completion: @escaping (_ result: ServiceResult<BudgetBillingInfo>) -> Void)
    
    /// Enroll the user in budget billing
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - completion: the completion block to execute upon completion.
    func enrollBudgetBilling(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Unenroll the user in budget billing
    ///
    /// - Parameters:
    ///   - accountNumber: The account to unenroll
    ///   - reason: The reason the user said they are unenrolling
    ///   - completion: the completion block to execute upon completion.
    func unenrollBudgetBilling(accountNumber: String, reason: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    

    /// Enroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - accountNumber: The account number to enroll
    ///   - email: Email address to send bills to
    ///   - completion: the completion block to execute upon completion.
    func enrollPaperlessBilling(accountNumber: String, email: String?, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Unenroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - accountNumber: The account number to unenroll
    ///   - completion: the completion block to execute upon completion.
    func unenrollPaperlessBilling(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Get the bill PDF data for display/saving
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - billDate: From account detail endpoint: BillingInfo.billDate
    ///   - completion: the completion block to execute upon completion.
    func fetchBillPdf(accountNumber: String, billDate: Date, completion: @escaping (_ result: ServiceResult<String>) -> Void)
    
    /// Get the BillingHistoryItems for display
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the bill for
    ///   - startDate: the start date of the desired history
    ///   - endDate: the end date of the desired history
    ///   - completion: the completion block to execute upon completion.
    func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date, completion: @escaping (_ result: ServiceResult<BillingHistory>) -> Void)
}

// MARK: - Reactive Extension to BillService
extension BillService {
    func fetchBudgetBillingInfo(accountNumber: String) -> Observable<BudgetBillingInfo> {
        return Observable.create { observer in
            self.fetchBudgetBillingInfo(accountNumber: accountNumber, completion: { (result: ServiceResult<BudgetBillingInfo>) in
                switch (result) {
                case ServiceResult.success(let info):
                    observer.onNext(info)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func enrollBudgetBilling(accountNumber: String) -> Observable<Void> {
        return Observable.create { observer in
            self.enrollBudgetBilling(accountNumber: accountNumber, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.success:
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func unenrollBudgetBilling(accountNumber: String, reason: String) -> Observable<Void> {
        return Observable.create { observer in
            self.unenrollBudgetBilling(accountNumber: accountNumber, reason: reason, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.success:
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func enrollPaperlessBilling(accountNumber: String, email: String?) -> Observable<Void> {
        return Observable.create { observer in
            self.enrollPaperlessBilling(accountNumber: accountNumber, email: email, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.success:
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func unenrollPaperlessBilling(accountNumber: String) -> Observable<Void> {
        return Observable.create { observer in
            self.unenrollPaperlessBilling(accountNumber: accountNumber, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.success:
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchBillPdf(accountNumber: String, billDate: Date) -> Observable<String> {
        return Observable.create { observer in
            self.fetchBillPdf(accountNumber: accountNumber, billDate: billDate, completion: { (result: ServiceResult<String>) in
                switch (result) {
                case ServiceResult.success(let billImageData):
                    observer.onNext(billImageData)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) -> Observable<BillingHistory> {
        return Observable.create { observer in
            self.fetchBillingHistory(accountNumber: accountNumber, startDate: startDate, endDate: endDate, completion: { (result: ServiceResult<BillingHistory>) in
                switch (result) {
                case ServiceResult.success(let billingHistory):
                    observer.onNext(billingHistory)
                    observer.onCompleted()
                case ServiceResult.failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
}
