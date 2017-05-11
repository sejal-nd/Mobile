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
    ///   - account: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain a BudgetBillingInfo 
    ////    object upon success, or the error on failure.
    func fetchBudgetBillingInfo(account: Account, completion: @escaping (_ result: ServiceResult<BudgetBillingInfo>) -> Void)
    
    /// Enroll the user in budget billing
    ///
    /// - Parameters:
    ///   - account: The account to enroll
    ///   - completion: the completion block to execute upon completion.
    func enrollBudgetBilling(account: Account, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Unenroll the user in budget billing
    ///
    /// - Parameters:
    ///   - account: The account to unenroll
    ///   - reason: The reason the user said they are unenrolling
    ///   - completion: the completion block to execute upon completion.
    func unenrollBudgetBilling(account: Account, reason: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    

    /// Enroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - account: The account number to enroll
    ///   - email: Email address to send bills to
    ///   - completion: the completion block to execute upon completion.
    func enrollPaperlessBilling(accountNumber: String, email: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Unenroll the user in paperless eBilling
    ///
    /// - Parameters:
    ///   - account: The account number to unenroll
    ///   - completion: the completion block to execute upon completion.
    func unenrollPaperlessBilling(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Get the bill PDF data for display/saving
    ///
    /// - Parameters:
    ///   - account: The account to get the bill for
    ///   - billDate: From account detail endpoint: BillingInfo.billDate
    ///   - completion: the completion block to execute upon completion.
    func fetchBillPdf(account: Account, billDate: Date, completion: @escaping (_ result: ServiceResult<String>) -> Void)
}

// MARK: - Reactive Extension to BillService
extension BillService {
    func fetchBudgetBillingInfo(account: Account) -> Observable<BudgetBillingInfo> {
        return Observable.create { observer in
            self.fetchBudgetBillingInfo(account: account, completion: { (result: ServiceResult<BudgetBillingInfo>) in
                switch (result) {
                case ServiceResult.Success(let info):
                    observer.onNext(info)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func enrollBudgetBilling(account: Account) -> Observable<Void> {
        return Observable.create { observer in
            self.enrollBudgetBilling(account: account, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func unenrollBudgetBilling(account: Account, reason: String) -> Observable<Void> {
        return Observable.create { observer in
            self.unenrollBudgetBilling(account: account, reason: reason, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func enrollPaperlessBilling(accountNumber: String, email: String) -> Observable<Void> {
        return Observable.create { observer in
            self.enrollPaperlessBilling(accountNumber: accountNumber, email: email, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
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
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchBillPdf(account: Account, billDate: Date) -> Observable<String> {
        return Observable.create { observer in
            self.fetchBillPdf(account: account, billDate: billDate, completion: { (result: ServiceResult<String>) in
                switch (result) {
                case ServiceResult.Success(let billImageData):
                    observer.onNext(billImageData)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
}
