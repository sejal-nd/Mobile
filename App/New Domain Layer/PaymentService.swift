//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// NOTE: The location of these static methods are subject to change

public struct PaymentService {
    
    static func autoPayInfo(accountNumber: String, completion: @escaping (Result<BGEAutoPayInfo, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayInfo(accountNumber: accountNumber), completion: completion)
    }
    
    static func autoPayEnroll(accountNumber: String, request: AutoPayEnrollRequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        var router: Router
        
        if request.isUpdate {
            router = .updateAutoPay(accountNumber: accountNumber, request: request)
        }
        else {
            router = .autoPayEnroll(accountNumber: accountNumber, request: request)
        }
        
        NetworkingLayer.request(router: router, completion: completion)
    }
    
    static func enrollAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayEnrollBGE(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func updateAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateAutoPayBGE(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func autoPayUnenroll(accountNumber: String, request: AutoPayUnenrollRequest, completion: @escaping (Result<AutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayUnenroll(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func deleteWalletItem(walletItem : WalletItem) {
        let opCo = Environment.shared.opco
//        let httpBodyParameters: [String: Any] = [
//            "account_number": AccountsStore.shared.accounts[0].accountNumber,
//            "wallet_item_id": walletItem.walletItemId ?? "",
//            "masked_wallet_item_acc_num": walletItem.maskedAccountNumber ?? "",
//            "biller_id": "\(opCo.rawValue)Registered",
//            "payment_category_type": walletItem.bankOrCard == .bank ? "check" : "credit"
//        ]
        
        let encodedObject = WalletItemDeleteRequest(accountNumber: AccountsStore.shared.accounts[0].accountNumber,
                                                    walletItemId: walletItem.walletItemId ?? "",
                                                    maskedAccountNumber: walletItem.maskedAccountNumber ?? "",
                                                    billerId: "\(opCo.rawValue)Registered",
                                                    paymentCategoryType: walletItem.bankOrCard == .bank ? "check" : "credit")
        
        print("REQ SCHEDULE")
            
            NetworkingLayer.request(router: .deleteWalletItem(request: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 4 SUCCESS")
                    
                case .failure(let error):
                    print("NetworkTest POST 4 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
            
            //            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<BillingHistoryResult, Error>) in
            //                                                                            switch result {
            //                case .success(let data):
            //
            //                    // fetch accounts todo
            //
            //                    print("NetworkTest POST 2 SUCCESS: \(data.billingHistoryItems.count) BREAK")
            //                case .failure(let error):
            //                    print("NetworkTest POST 2 FAIL: \(error)")
            //                    //                completion(.failure(error))
            //                }
            //            }

    }
    
    static func schedulePayment(accountNumber: String, request: ScheduledPaymentUpdateRequest, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .scheduledPayment(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func cancelSchduledPayment(accountNumber: String, paymentId: String, request: SchedulePaymentCancelRequest, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
            NetworkingLayer.request(router: .scheduledPaymentDelete(accountNumber: accountNumber, paymentId: paymentId, request: request), completion: completion)
    }
    
    static func updateScheduledPayment(paymentId: String, accountNumber: String, request: ScheduledPaymentUpdateRequest, completion: @escaping (Result<GenericResponse, NetworkingError>) -> ()) {
            NetworkingLayer.request(router: .scheduledPaymentUpdate(accountNumber: accountNumber, paymentId: paymentId, request: request), completion: completion)
    }
}
