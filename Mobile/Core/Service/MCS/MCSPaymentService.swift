//
//  MCSPaymentService.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MCSPaymentService: PaymentService {

    func fetchBGEAutoPayInfo(accountNumber: String) -> Observable<BGEAutoPayInfo> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/recurring")
            .map { json in
                guard let dict = json as? NSDictionary, let autoPayInfo = BGEAutoPayInfo.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return autoPayInfo
        }
    }
    
    func enrollInAutoPayBGE(accountNumber: String,
                            walletItemId: String?,
                            amountType: AmountType,
                            amountThreshold: String,
                            paymentDaysBeforeDue: String,
                            effectivePeriod: EffectivePeriod,
                            effectiveEndDate: Date?,
                            effectiveNumPayments: String,
                            isUpdate: Bool) -> Observable<Void> {
        let path = "accounts/\(accountNumber)/payments/recurring"

        var params = ["amount_type": amountType.rawValue,
                      "payment_date_type": "before due",
                      "payment_days_before_due": paymentDaysBeforeDue,
                      "effective_period": effectivePeriod.rawValue]

        if let walletId = walletItemId {
            params["wallet_item_id"] = walletId
        }
        if amountType == .upToAmount {
            params["amount_threshold"] = amountThreshold
        }
        if effectivePeriod == .endDate {
            params["effective_end_date"] = effectiveEndDate!.apiFormatString
        } else if effectivePeriod == .maxPayments {
            params["effective_number_of_payments"] = effectiveNumPayments
        }

        params["auto_pay_request_type"] = isUpdate ? "Update" : "Start"
        let observable: Observable<Any>
        if isUpdate {
            observable = MCSApi.shared.put(pathPrefix: .auth, path: path, params: params)
        } else { // Start
            observable = MCSApi.shared.post(pathPrefix: .auth, path: path, params: params)
        }
        
        return observable.mapTo(())
            .do(onNext: {
                RxNotifications.shared.accountDetailUpdated.onNext(())
            })
    }
    
    func unenrollFromAutoPayBGE(accountNumber: String) -> Observable<Void> {
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/recurring/delete", params: nil)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.accountDetailUpdated.onNext(())
            })
    }

    func enrollInAutoPay(accountNumber: String,
                         nameOfAccount: String,
                         bankAccountType: String,
                         routingNumber: String,
                         bankAccountNumber: String,
                         isUpdate: Bool) -> Observable<Void> {

        let path = "accounts/\(accountNumber)/payments/recurring"

        let params: [String: Any] = [
            "bank_details": [
                "name_on_account": nameOfAccount,
                "bank_account_type": bankAccountType,
                "routing_number": routingNumber,
                "bank_name": "N/A",
                "bank_account_number": bankAccountNumber,
            ],
            "auto_pay_request_type": isUpdate ? "Update": "Start"
        ]

        let observable: Observable<Any>
        if isUpdate {
            observable = MCSApi.shared.put(pathPrefix: .auth, path: path, params: params)
        } else {
            observable = MCSApi.shared.post(pathPrefix: .auth, path: path, params: params)
        }
        
        return observable.mapTo(())
            .do(onNext: {
                RxNotifications.shared.accountDetailUpdated.onNext(())
            })
    }

    func unenrollFromAutoPay(accountNumber: String, reason: String) -> Observable<Void> {

        let params: [String: Any] = ["reason": reason, "comments": ""]

        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/recurring/delete", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.accountDetailUpdated.onNext(())
            })
    }

    func schedulePayment(payment: Payment) -> Observable<String> {
        let opCo = Environment.shared.opco
        let params: [String: Any] = [
            "masked_wallet_item_account_number": payment.maskedWalletAccountNumber,
            "payment_amount": String.init(format: "%.02f", payment.paymentAmount),
            "payment_category_type": payment.paymentType.rawValue,
            "payment_date": payment.paymentDate.paymentFormatString,
            "wallet_id" : payment.walletId,
            "wallet_item_id" : payment.walletItemId,
            "is_existing_account": payment.existingAccount,
            "is_save_account": payment.saveAccount,
            "biller_id": "\(opCo.rawValue)Registered", // Still needed?
            "auth_sess_token": "" // Still needed?
        ]
        
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(payment.accountNumber)/payments/schedule", params: params)
            .map { json -> String in
                guard let dict = json as? NSDictionary, let confirmation = dict["confirmationNumber"] as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                return confirmation
            }
            .do(onNext: { _ in
                RxNotifications.shared.recentPaymentsUpdated.onNext(())
                AppRating.logRatingEvent()
            })
    }
    
    func fetchPaymentDetails(accountNumber: String, paymentId: String) -> Observable<PaymentDetail> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/schedule/\(paymentId)")
            .map { json in
                guard let dict = json as? NSDictionary,
                    let paymentDetail = PaymentDetail.from(dict) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                return paymentDetail
            }
    }
    
    func updatePayment(paymentId: String, payment: Payment) -> Observable<Void> {
        let opCo = Environment.shared.opco
        let params: [String: Any] = [
            "masked_wallet_item_account_number": payment.maskedWalletAccountNumber,
            "payment_amount": String.init(format: "%.02f", payment.paymentAmount),
            "payment_category_type": payment.paymentType.rawValue,
            "payment_date": payment.paymentDate.paymentFormatString,
            "payment_id": paymentId,
            "wallet_id" : payment.walletId,
            "wallet_item_id" : payment.walletItemId,
            "is_existing_account": payment.existingAccount,
            "biller_id": "\(opCo.rawValue)Registered", // Still needed?
            "auth_sess_token": "" // Still needed?
        ]
        return updatePaymentInternal(accountNumber: payment.accountNumber, paymentId: paymentId, params: params)
    }
    
    private func updatePaymentInternal(accountNumber: String, paymentId: String, params: [String: Any]) -> Observable<Void> {
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/schedule/\(paymentId)", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.recentPaymentsUpdated.onNext(())
                AppRating.logRatingEvent()
            })
    }
    
    func cancelPayment(accountNumber: String, paymentId: String, paymentDetail: PaymentDetail) -> Observable<Void> {
        let opCo = Environment.shared.opco
        let params: [String: Any] = [
            "payment_id": paymentId,
            "payment_amount": String.init(format: "%.02f", paymentDetail.paymentAmount),
            "wallet_item_id" : paymentDetail.walletItemId ?? "",
            "cancel_payment_method": "", // Needed?
            "biller_id": "\(opCo.rawValue)Registered", // Still needed?
            "auth_sess_token": "" // Still needed?
        ]
        return cancelPaymentInternal(accountNumber: accountNumber, paymentId: paymentId, params: params)
    }
    
    private func cancelPaymentInternal(accountNumber: String, paymentId: String, params: [String: Any]) -> Observable<Void> {
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/schedule/\(paymentId)", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.recentPaymentsUpdated.onNext(())
                AppRating.logRatingEvent()
            })
    }
}
