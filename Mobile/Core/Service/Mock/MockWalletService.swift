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
        var walletItems: [WalletItem]
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        if loggedInUsername == "billCardNoDefaultPayment" {
            walletItems = []
        } else if loggedInUsername == "billCardWithDefaultPayment" {
            walletItems = [
                WalletItem(nickName: "Test Nickname", isDefault: true),
                WalletItem(nickName: "Expired Card", walletItemStatusType: "expired", isDefault: false, cardIssuer: "Visa", bankOrCard: .card)
            ]
        } else if loggedInUsername == "billCardWithExpiredDefaultPayment" {
            walletItems = [
                WalletItem(nickName: "Expired Card", walletItemStatusType: "expired", isDefault: true, cardIssuer: "Visa", bankOrCard: .card)
            ]
        }else if loggedInUsername == "billCardWithDefaultCcPayment" {
            walletItems = [
                WalletItem(nickName: "Test Nickname", isDefault: true, cardIssuer: "Visa", bankOrCard: .card),
            ]
        } else if AccountsStore.shared.currentAccount.accountNumber == "13" { // Set this to test no OTP items
            walletItems = [
                WalletItem(nickName: "Test Nickname", cardIssuer: "Visa", bankOrCard: .card),
                WalletItem(nickName: "Test Nickname 2", cardIssuer: "Mastercard", bankOrCard: .card)
            ]
        } else {
            walletItems = [
                WalletItem(nickName: "Test Nickname"),
                WalletItem(nickName: "Test Nickname 2", isDefault: true, cardIssuer: "Visa", bankOrCard: .card)
            ]
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            completion(.success(walletItems))
        }
    }
    
    func fetchBankName(routingNumber: String, completion: @escaping (_ result: ServiceResult<String>) -> Void) {
        completion(ServiceResult.failure(ServiceError(serviceCode: "")))
    }
    
    func addBankAccount(_ bankAccount : BankAccount,
                        forCustomerNumber: String,
                        completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Void) {
        if forCustomerNumber == "13" { // Simulate duplicate payment
            completion(.failure(ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue)))
        } else {
            let walletResult = WalletItemResult(responseCode: 1, statusMessage: "pretty good", walletItemId: "123")
            completion(.success(walletResult))
        }
    }
    
    func addCreditCard(_ creditCard: CreditCard,
                       forCustomerNumber: String,
                       completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Void) {
        if forCustomerNumber == "13" { // Simulate duplicate payment
            completion(.failure(ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue)))
        } else {
            let walletResult = WalletItemResult(responseCode: 1, statusMessage: "pretty good", walletItemId: "123")
            completion(.success(walletResult))
        }
    }

    func updateCreditCard(_ walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String,
                          completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.failure(ServiceError(serviceCode: "")))
    }

    func deletePaymentMethod(_ walletItem : WalletItem,
                             completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(ServiceResult.failure(ServiceError(serviceCode: "")))
    }

    func setOneTouchPayItem(walletItemId: String,
                            walletId: String?,
                            customerId: String,
                            completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        completion(.success(()))
    }
    
    func removeOneTouchPayItem(customerId: String,
                               completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
}
