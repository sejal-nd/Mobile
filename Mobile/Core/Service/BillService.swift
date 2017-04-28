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
}
