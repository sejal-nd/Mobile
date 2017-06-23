//
//  PaymentService.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol PaymentService {

    /// Get AutoPay enrollment information (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the info for
    ///   - completion: the completion block to execute upon completion.
    func fetchBGEAutoPayInfo(accountNumber: String, completion: @escaping (_ result: ServiceResult<BGEAutoPayInfo>) -> Void)
    
    
    /// Enroll in AutoPay (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to get the info for
    ///   - completion: the completion block to execute upon completion.
    //func enrollAutoPayBGE(accountNumber: String, walletItemId: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
}

// MARK: - Reactive Extension to PaymentService
extension PaymentService {
    
    func fetchBGEAutoPayInfo(accountNumber: String) -> Observable<BGEAutoPayInfo> {
        return Observable.create { observer in
            self.fetchBGEAutoPayInfo(accountNumber: accountNumber, completion: { (result: ServiceResult<BGEAutoPayInfo>) in
                switch (result) {
                case ServiceResult.Success(let autoPayInfo):
                    observer.onNext(autoPayInfo)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
}
