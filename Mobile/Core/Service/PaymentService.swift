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
    func fetchBGEAutoPayInfo(accountNumber: String) -> Observable<BGEAutoPayInfo>


    /// Enroll in AutoPay (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - walletItemId: The selected wallet item to use for AutoPay payments
    ///   - Params 3-8: BGE AutoPay Settings
    ///   - isUpdate: Denotes whether the account is a change, or new
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
    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void>
    
    /// Schedule a payment
    ///
    /// - Parameters:
    ///   - payment: the payment to schedule
    func schedulePayment(payment: Payment) -> Observable<String>
    
    /// Schedule a payment
    ///
    /// - Parameters:
    ///   - creditCard: the card details
    func scheduleBGEOneTimeCardPayment(accountNumber: String, paymentAmount: Double, paymentDate: Date, creditCard: CreditCard) -> Observable<String>
    
    /// Gets full details of an one time payment transaction
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch for
    ///   - paymentId: the paymentId
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail>
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void>
    
    func cancelPayment(accountNumber: String, paymentId: String, paymentDetail: PaymentDetail) -> Observable<Void>
}
