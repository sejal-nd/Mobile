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
    ///   - accountNumber: The account to enroll
    ///   - walletItemId: The selected wallet item to use for AutoPay payments
    ///   - Params 3-9: BGE AutoPay Settings
    ///   - isUpdate: Denotes whether the account is a change, or new
    ///   - completion: the completion block to execute upon completion.
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDateType: PaymentDateType,
                            paymentDaysBeforeDue: String,
                            effectivePeriod: EffectivePeriod,
                            effectiveEndDate: Date?,
                            effectiveNumPayments: String,
                            isUpdate: Bool,
                            completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Unenroll in AutoPay (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - completion: the completion block to execute upon completion.
    func unenrollFromAutoPayBGE(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void)

    /// Enroll in AutoPay (ComEd & PECO only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - nameOfAccount: The name on the bank account
    ///   - bankAccountType: Checking/Saving
    ///   - routingNumber: The routing number of the bank account
    ///   - bankAccountNumber: The account number for the bank account
    ///   - isUpdate: Denotes whether the account is a change, or new
    ///   - completion: the completion block to execute upon completion.
    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: BankAccountType,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool,
                         completion: @escaping (_ result: ServiceResult<Void>) -> Void)

    /// Unenroll in AutoPay (ComEd & PECO only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to unenroll
    ///   - reason: Reason for unenrolling
    ///   - completion: the completion block to execute upon completion.
    func unenrollFromAutoPay(accountNumber: String,
                             reason: String,
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

    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDateType: PaymentDateType,
                            paymentDatesBeforeDue: String,
                            effectivePeriod: EffectivePeriod,
                            effectiveEndDate: Date?,
                            effectiveNumPayments: String,
                            isUpdate: Bool) -> Observable<Void> {
        
        return Observable.create { observer in
            self.enrollInAutoPayBGE(accountNumber: accountNumber, walletItemId: walletItemId, amountType: amountType, amountThreshold: amountThreshold, paymentDateType: paymentDateType, paymentDaysBeforeDue: paymentDatesBeforeDue, effectivePeriod: effectivePeriod, effectiveEndDate: effectiveEndDate, effectiveNumPayments: effectiveNumPayments, isUpdate: isUpdate, completion: { (result: ServiceResult<Void>) in
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
    
    func unenrollFromAutoPayBGE(accountNumber: String) -> Observable<Void> {
        
        return Observable.create { observer in
            self.unenrollFromAutoPayBGE(accountNumber: accountNumber)
            { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }

    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: BankAccountType,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool) -> Observable<Void> {

        return Observable.create { observer in
            self.enrollInAutoPay(accountNumber: accountNumber,
                                 nameOfAccount: nameOfAccount,
                                 bankAccountType: bankAccountType,
                                 routingNumber: routingNumber,
                                 bankAccountNumber: bankAccountNumber,
                                 isUpdate: isUpdate)
            { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success(_):
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }

    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void> {

        return Observable.create { observer in
            self.unenrollFromAutoPay(accountNumber: accountNumber,
                                     reason: reason)
            { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success(_):
                    observer.onNext()
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }


}
