//
//  AuthenticatedService.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// NOTE: The location of these static methods are subject to change

public struct PaymentServiceNew {
    
    static func autoPayInfo(accountNumber: String, completion: @escaping (Result<NewBGEAutoPayInfo, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayInfo(accountNumber: accountNumber), completion: completion)
    }
    
    static func autoPayEnroll(accountNumber: String, request: AutoPayEnrollRequest, completion: @escaping (Result<NewAutoPayResult, NetworkingError>) -> ()) {
        var router: Router
        
        if request.isUpdate {
            router = .updateAutoPay(accountNumber: accountNumber, request: request)
        }
        else {
            router = .autoPayEnroll(accountNumber: accountNumber, request: request)
        }
        
        NetworkingLayer.request(router: router, completion: completion)
    }
    
    static func enrollAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest, completion: @escaping (Result<NewAutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayEnrollBGE(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func updateAutoPayBGE(accountNumber: String, request: AutoPayEnrollBGERequest, completion: @escaping (Result<NewAutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .updateAutoPayBGE(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func autoPayUnenroll(accountNumber: String, request: AutoPayUnenrollRequest, completion: @escaping (Result<NewAutoPayResult, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .autoPayUnenroll(accountNumber: accountNumber, request: request), completion: completion)
    }
    
    static func deleteWalletItem(walletItem : WalletItem) {
        let opCo = Environment.shared.opco
//        let httpBodyParameters: [String: Any] = [
//            "account_number": AccountsStore.shared.accounts[0].accountNumber,
//            "wallet_item_id": walletItem.walletItemId ?? "",
//            "masked_wallet_item_acc_num": walletItem.maskedWalletItemAccountNumber ?? "",
//            "biller_id": "\(opCo.rawValue)Registered",
//            "payment_category_type": walletItem.bankOrCard == .bank ? "check" : "credit"
//        ]
        
        let encodedObject = WalletItemDeleteRequest(accountNumber: AccountsStore.shared.accounts[0].accountNumber,
                                                    walletItemId: walletItem.walletItemId ?? "",
                                                    maskedWalletItemAccountNumber: walletItem.maskedWalletItemAccountNumber ?? "",
                                                    billerId: "\(opCo.rawValue)Registered",
                                                    paymentCategoryType: walletItem.bankOrCard == .bank ? "check" : "credit")
        
        print("REQ SCHEDULE")
            
            NetworkingLayer.request(router: .deleteWalletItem(encodable: encodedObject)) { (result: Result<GenericResponse, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 4 SUCCESS")
                    
                case .failure(let error):
                    print("NetworkTest POST 4 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
            
            //            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<NewBillingHistoryResult, Error>) in
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
    
    static func pay(customerId: String,
                    bankOrCard: BankOrCard,
                    temporary: Bool,
                    isWalletEmpty: Bool,
                    walletItemId: String? = nil) {
//        var httpBodyParameters = [
//            "pmCategory": bankOrCard == .bank ? "DD" : "CC", // "DC" = Debit Card
//            "postbackUrl": "",
//        ]
//
//        var strParameters = "pageView=mobile;postMessagePmDetailsOrigin=\(Environment.shared.mcsConfig.paymentusUrl);"
//        if temporary {
//            strParameters += "nickname=false;primaryPM=false;"
//        } else {
//            if isWalletEmpty { // If wallet is empty, hide the default checkbox because Paymentus automatically sets first wallet items as default
//                strParameters += "primaryPM=false;"
//            }
//            httpBodyParameters["ownerId"] = customerId
//        }
//        httpBodyParameters["strParam"] = strParameters
//
//        if let wid = walletItemId { // Indicates that this is an edit operation (as opposed to an add)
//            httpBodyParameters["wallet_item_id"] = wid
//        }
        
        var ownerId: String?
        var walletItemId: String?
        
        var stringParameters = "pageView=mobile;postMessagePmDetailsOrigin=\(Environment.shared.mcsConfig.paymentusUrl);"
        if temporary {
            stringParameters += "nickname=false;primaryPM=false;"
        } else {
            if isWalletEmpty { // If wallet is empty, hide the default checkbox because Paymentus automatically sets first wallet items as default
                stringParameters += "primaryPM=false;"
            }
            ownerId = customerId
        }
        
        if let wid = walletItemId { // Indicates that this is an edit operation (as opposed to an add)
            walletItemId = wid
        }
        
        // "DC" = Debit Card
        let encodedObject = PaymentRequest(category: bankOrCard == .bank ? "DD" : "CC",
                                           postbackURL: "",
                                           ownerId: ownerId,
                                           stringParameter: stringParameters,
                                           walletItemId: walletItemId)
        
            print("REQ SCHEDULE")
            
            NetworkingLayer.request(router: .payment(encodable: encodedObject)) { (result: Result<NewPaymentResult, NetworkingError>) in
                switch result {
                case .success(let data):
                    
                    // fetch accounts todo
                    
                    print("NetworkTest POST 3 SUCCESS: \(data.data) BREAK")
                    
                case .failure(let error):
                    print("NetworkTest POST 3 FAIL: \(error)")
                    //                completion(.failure(error))
                }
            }
            
            //            ServiceLayer.request(router: .billingHistory(accountNumber: accountNumber, httpBody: httpBody)) { (result: Result<NewBillingHistoryResult, Error>) in
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
