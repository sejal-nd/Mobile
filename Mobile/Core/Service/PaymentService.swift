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
    func fetchBGEAutoPayInfo(accountNumber: String) -> Observable<BGEAutoPayInfo>


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
                            isUpdate: Bool) -> Observable<Void>
    
    /// Unenroll in AutoPay (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - completion: the completion block to execute upon completion.
    func unenrollFromAutoPayBGE(accountNumber: String) -> Observable<Void>

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
                         isUpdate: Bool) -> Observable<Void>

    /// Unenroll in AutoPay (ComEd & PECO only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to unenroll
    ///   - reason: Reason for unenrolling
    ///   - completion: the completion block to execute upon completion.
    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void>
    
    /// Fetch the next 90 days that PECO users are elibile to make payments
    ///
    /// - Parameters:
    ///   - completion: the completion block to execute upon completion.
    func fetchWorkdays() -> Observable<[Date]>
    
    /// Schedule a payment
    ///
    /// - Parameters:
    ///   - payment: the payment to schedule
    ///   - completion: the completion block to execute upon completion.
    func schedulePayment(payment: Payment) -> Observable<String>
    
    /// Schedule a payment
    ///
    /// - Parameters:
    ///   - creditCard: the card details
    ///   - completion: the completion block to execute upon completion.
    func scheduleBGEOneTimeCardPayment(accountNumber: String, paymentAmount: Double, paymentDate: Date, creditCard: CreditCard) -> Observable<String>
    
    /// Gets full details of an one time payment transaction
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch for
    ///   - paymentId: the paymentId
    ///   - completion: the completion block to execute upon completion.
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail>
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void>
    
    func cancelPayment(accountNumber: String, paymentId: String, bankOrCard: BankOrCard?, paymentDetail: PaymentDetail) -> Observable<Void>
}
