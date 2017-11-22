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
    ///   - Params 3-8: BGE AutoPay Settings
    ///   - isUpdate: Denotes whether the account is a change, or new
    ///   - completion: the completion block to execute upon completion.
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
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
    
    /// Fetch the next 90 days that PECO users are elibile to make payments
    ///
    /// - Parameters:
    ///   - completion: the completion block to execute upon completion.
    func fetchWorkdays(completion: @escaping (_ result: ServiceResult<[Date]>) -> Void)
    
    /// Schedule a payment
    ///
    /// - Parameters:
    ///   - payment: the payment to schedule
    ///   - completion: the completion block to execute upon completion.
    func schedulePayment(payment: Payment, completion: @escaping (_ result: ServiceResult<String>) -> Void)
    
    /// Schedule a payment
    ///
    /// - Parameters:
    ///   - creditCard: the card details
    ///   - completion: the completion block to execute upon completion.
    func scheduleBGEOneTimeCardPayment(accountNumber: String, paymentAmount: Double, paymentDate: Date, creditCard: CreditCard, completion: @escaping (ServiceResult<String>) -> Void)
    
    /// Gets full details of an one time payment transaction
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch for
    ///   - paymentId: the paymentId
    ///   - completion: the completion block to execute upon completion.
    func fetchPaymentDetails(accountNumber: String, paymentId: String, completion: @escaping (_ result: ServiceResult<PaymentDetail>) -> Void)
    
    func updatePayment(paymentId: String, payment: Payment, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    func cancelPayment(accountNumber: String, paymentId: String, bankOrCard: BankOrCard?, paymentDetail: PaymentDetail, completion: @escaping (_ result: ServiceResult<Void>) -> Void)
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
                            paymentDatesBeforeDue: String,
                            effectivePeriod: EffectivePeriod,
                            effectiveEndDate: Date?,
                            effectiveNumPayments: String,
                            isUpdate: Bool) -> Observable<Void> {
        
        return Observable.create { observer in
            self.enrollInAutoPayBGE(accountNumber: accountNumber, walletItemId: walletItemId, amountType: amountType, amountThreshold: amountThreshold, paymentDaysBeforeDue: paymentDatesBeforeDue, effectivePeriod: effectivePeriod, effectiveEndDate: effectiveEndDate, effectiveNumPayments: effectiveNumPayments, isUpdate: isUpdate, completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success():
                    observer.onNext(())
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
                    observer.onNext(())
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
                    observer.onNext(())
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
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchWorkdays() -> Observable<[Date]> {
        return Observable.create { observer in
            self.fetchWorkdays(completion: { (result: ServiceResult<[Date]>) in
                switch (result) {
                case ServiceResult.Success(let workdays):
                    observer.onNext(workdays)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            return Disposables.create()
        }
    }

    func schedulePayment(payment: Payment) -> Observable<Void> {
        
        return Observable.create { observer in
            self.schedulePayment(payment: payment)
            { (result: ServiceResult<String>) in
                switch (result) {
                case ServiceResult.Success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func scheduleBGEOneTimeCardPayment(accountNumber: String, paymentAmount: Double, paymentDate: Date, creditCard: CreditCard) -> Observable<Void> {
        
        return Observable.create { observer in
            self.scheduleBGEOneTimeCardPayment(accountNumber: accountNumber, paymentAmount: paymentAmount, paymentDate: paymentDate, creditCard: creditCard)
            { (result: ServiceResult<String>) in
                switch (result) {
                case ServiceResult.Success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail> {
        
        return Observable.create { observer in
            self.fetchPaymentDetails(accountNumber: accountNumber, paymentId: paymentId)
            { (result: ServiceResult<PaymentDetail>) in
                switch (result) {
                case ServiceResult.Success(let paymentDetail):
                    observer.onNext(paymentDetail)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void> {
        
        return Observable.create { observer in
            self.updatePayment(paymentId: paymentId, payment: payment)
            { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success(_):
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
    
    func cancelPayment(accountNumber: String, paymentId: String, bankOrCard: BankOrCard?, paymentDetail: PaymentDetail) -> Observable<Void> {
        
        return Observable.create { observer in
            self.cancelPayment(accountNumber: accountNumber, paymentId: paymentId, bankOrCard: bankOrCard, paymentDetail: paymentDetail)
            { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success():
                    observer.onNext(())
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create()
        }
    }
}
