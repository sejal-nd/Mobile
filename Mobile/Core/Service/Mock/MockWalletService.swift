//
//  MockWalletService.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

struct MockWalletService: WalletService {
    func fetchWalletItems(completion: @escaping (_ result: ServiceResult<[WalletItem]>) -> Void) {
        let walletItems = [
            WalletItem(nickName: "Test Nickname"),
            WalletItem(nickName: "Test Nickname 2", isDefault: true)
        ]
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            completion(.Success(walletItems))
        }
        //completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }
    
    func fetchBankName(routingNumber: String, completion: @escaping (_ result: ServiceResult<String>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }
    
    func addBankAccount(_ bankAccount : BankAccount,
                        forCustomerNumber: String,
                        completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }
    
    func addCreditCard(_ creditCard: CreditCard,
                       forCustomerNumber: String,
                       completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }

    func updateCreditCard(_ walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String,
                          completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }

    func deletePaymentMethod(_ walletItem : WalletItem,
                             completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }

    func setOneTouchPayItem(walletItemId: String,
                            walletId: String?,
                            customerId: String,
                            completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.Failure(ServiceError(serviceCode: "")))
    }
    
    func removeOneTouchPayItem(customerId: String,
                               completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
}
