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
    ///   - Params 3-5: BGE AutoPay Settings
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDaysBeforeDue: String) -> Observable<Void>
    
    
    /// Update AutoPay Settings (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - walletItemId: The selected wallet item to use for AutoPay payments
    ///   - Params 4-6: BGE AutoPay Settings
    func updateAutoPaySettingsBGE(accountNumber: String,
                                  walletItemId: String?,
                                  confirmationNumber: String,
                                  amountType: AmountType,
                                  amountThreshold: String,
                                  paymentDaysBeforeDue: String) -> Observable<Void>
    
    /// Unenroll in AutoPay (BGE only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    func unenrollFromAutoPayBGE(accountNumber: String, confirmationNumber: String) -> Observable<Void>

    /// Enroll in AutoPay (ComEd & PECO only)
    ///
    /// - Parameters:
    ///   - accountNumber: The account to enroll
    ///   - nameOfAccount: The name on the bank account
    ///   - bankAccountType: "checking" or "saving"
    ///   - routingNumber: The routing number of the bank account
    ///   - bankAccountNumber: The account number for the bank account
    ///   - isUpdate: Denotes whether the account is a change, or new
    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: String,
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
    ///   - accountNumber: The account
    ///   - paymentAmount: The amount to be paid
    ///   - paymentDate: the date to schedule the payment for
    ///   - walletId: Always the customerIdentifier
    ///   - walletItem: The WalletItem being used to make the payment
    func schedulePayment(accountNumber: String,
                         paymentAmount: Double,
                         paymentDate: Date,
                         walletId: String,
                         walletItem: WalletItem) -> Observable<String>

    func updatePayment(paymentId: String,
                       accountNumber: String,
                       paymentAmount: Double,
                       paymentDate: Date,
                       walletId: String,
                       walletItem: WalletItem) -> Observable<String>
    
    func cancelPayment(accountNumber: String, paymentAmount: Double, paymentId: String) -> Observable<Void>
}
