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
                            paymentDaysBeforeDue: String) -> Observable<Void> {
        let path = "accounts/\(accountNumber)/payments/recurring"

        var params = ["amount_type": amountType.rawValue,
                      "payment_date_type": "before due",
                      "payment_days_before_due": paymentDaysBeforeDue,
                      "auto_pay_request_type": "Start"]

        if let walletId = walletItemId {
            params["wallet_item_id"] = walletId
        }
        if amountType == .upToAmount {
            params["amount_threshold"] = amountThreshold
        }
        
        return MCSApi.shared.post(pathPrefix: .auth, path: path, params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.accountDetailUpdated.onNext(())
            })
    }
    
    func updateAutoPaySettingsBGE(accountNumber: String,
                                  walletItemId: String?,
                                  confirmationNumber: String,
                                  amountType: AmountType,
                                  amountThreshold: String,
                                  paymentDaysBeforeDue: String) -> Observable<Void> {
        let path = "accounts/\(accountNumber)/payments/recurring"
        
        var params = ["amount_type": amountType.rawValue,
                      "payment_date_type": "before due",
                      "payment_days_before_due": paymentDaysBeforeDue,
                      "auto_pay_request_type": "Update",
                      "confirmation_number": confirmationNumber]
        
        if let walletId = walletItemId {
            params["wallet_item_id"] = walletId
        }
        if amountType == .upToAmount {
            params["amount_threshold"] = amountThreshold
        }
        
        return MCSApi.shared.put(pathPrefix: .auth, path: path, params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.accountDetailUpdated.onNext(())
            })
    }
    
    func unenrollFromAutoPayBGE(accountNumber: String, confirmationNumber: String) -> Observable<Void> {
        let params = ["confirmation_number": confirmationNumber]
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/recurring/delete", params: params)
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
    
    func schedulePayment(accountNumber: String,
                         paymentAmount: Double,
                         paymentDate: Date,
                         walletId: String,
                         walletItem: WalletItem) -> Observable<String> {
        let opCo = Environment.shared.opco
        let params: [String: Any] = [
            "payment_amount": String.init(format: "%.02f", paymentAmount),
            "payment_date": paymentDate.paymentFormatString,
            "payment_category_type": walletItem.bankOrCard == .bank ? "Check" : "Credit",
            "wallet_id": walletId,
            "wallet_item_id": walletItem.walletItemId!,
            "is_existing_account": !walletItem.isTemporary,
            "biller_id": "\(opCo.rawValue)Registered"
        ]

        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/schedule", params: params)
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
    
    func updatePayment(paymentId: String,
                       accountNumber: String,
                       paymentAmount: Double,
                       paymentDate: Date,
                       walletId: String,
                       walletItem: WalletItem) -> Observable<String> {
        let opCo = Environment.shared.opco
        var params: [String: Any] = [
            "payment_amount": String.init(format: "%.02f", paymentAmount),
            "payment_date": paymentDate.paymentFormatString,
            "payment_category_type": walletItem.bankOrCard == .bank ? "Check" : "Credit",
            "payment_id": paymentId,
            "biller_id": "\(opCo.rawValue)Registered"
        ]
        
        if !walletItem.isEditingItem, let walletItemId = walletItem.walletItemId { // User selected a new payment method
            params["wallet_id"] = walletId
            params["wallet_item_id"] = walletItemId
            params["is_existing_account"] = !walletItem.isTemporary
        }
        
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/schedule/\(paymentId)", params: params)
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
    
    func cancelPayment(accountNumber: String, paymentId: String) -> Observable<Void> {
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/payments/schedule/\(paymentId)", params: nil)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.recentPaymentsUpdated.onNext(())
                AppRating.logRatingEvent()
            })
    }

}
