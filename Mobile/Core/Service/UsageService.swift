//
//  UsageService.swift
//  Mobile
//
//  Created by Marc Shilling on 10/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol UsageService {
    
    /// Compares how usage impacted your bill between cycles
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - yearAgo: if true, compares data to the previous year, if false, compares to the previous bill
    ///   - gas: if true, compares gas usage data, if false, compares electric
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a BillComparison object on success, or a ServiceError on failure.
    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool, completion: @escaping (_ result: ServiceResult<BillComparison>) -> Void)
    
    /// Fetches your projected usage
    ///
    /// - Parameters:
    ///   - accountNumber: the account to fetch data for
    ///   - premiseNumber: the premise to fetch data for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain a TODO object on success, or a ServiceError on failure.
    func fetchBillForecast(accountNumber: String, premiseNumber: String, completion: @escaping (_ result: ServiceResult<[BillForecast?]>) -> Void)
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to RegistrationService
extension UsageService {

    func fetchBillComparison(accountNumber: String, premiseNumber: String, yearAgo: Bool, gas: Bool) -> Observable<BillComparison> {
        return Observable.create { observer in
            self.fetchBillComparison(accountNumber: accountNumber, premiseNumber: premiseNumber, yearAgo: yearAgo, gas: gas, completion: { (result: ServiceResult<BillComparison>) in
                switch (result) {
                case ServiceResult.Success(let billComparison):
                    observer.onNext(billComparison)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    func fetchBillForecast(accountNumber: String, premiseNumber: String) -> Observable<[BillForecast?]> {
        return Observable.create { observer in
            self.fetchBillForecast(accountNumber: accountNumber, premiseNumber: premiseNumber, completion: { (result: ServiceResult<[BillForecast?]>) in
                switch (result) {
                case ServiceResult.Success(let billForecast):
                    observer.onNext(billForecast)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
    
}
