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
    func enrollOrUpdateAutoPayBGE(accountNumber: String,
                                  walletItemId: String?,
                                  amountType: AmountType,
                                  amountThreshold: String,
                                  paymentDateType: PaymentDateType,
                                  paymentDaysBeforeDue: String,
                                  effectivePeriod: EffectivePeriod,
                                  effectiveEndDate: Date?,
                                  effectiveNumPayments: String,
                                  update: Bool,
                                  completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
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
    
    func enrollOrUpdateAutoPayBGE(accountNumber: String,
                                  walletItemId: String?,
                                  amountType: AmountType,
                                  amountThreshold: String,
                                  paymentDateType: PaymentDateType,
                                  paymentDatesBeforeDue: String,
                                  effectivePeriod: EffectivePeriod,
                                  effectiveEndDate: Date?,
                                  effectiveNumPayments: String,
                                  update: Bool) -> Observable<Void> {
        return Observable.create { observer in
            self.enrollOrUpdateAutoPayBGE(accountNumber: accountNumber, walletItemId: walletItemId, amountType: amountType, amountThreshold: amountThreshold, paymentDateType: paymentDateType, paymentDaysBeforeDue: paymentDatesBeforeDue, effectivePeriod: effectivePeriod, effectiveEndDate: effectiveEndDate, effectiveNumPayments: effectiveNumPayments, update: update, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success():
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }
    
}
