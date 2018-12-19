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
    func fetchWalletItems() -> Observable<[WalletItem]> {
        var walletItems: [WalletItem]
        let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)
        if loggedInUsername == "billCardNoDefaultPayment" {
            walletItems = []
        } else if loggedInUsername == "billCardWithDefaultPayment" {
            walletItems = [
                WalletItem(nickName: "Test Nickname", isDefault: true),
                WalletItem(nickName: "Expired Card", isDefault: false, cardIssuer: "Visa", bankOrCard: .card)
            ]
        } else if loggedInUsername == "billCardWithExpiredDefaultPayment" {
            walletItems = [
                WalletItem(nickName: "Expired Card", walletItemStatusType: "expired", expirationDate: "01/2018", isDefault: true, cardIssuer: "Visa", bankOrCard: .card)
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

        return Observable.just(walletItems).delay(1, scheduler: MainScheduler.instance)
    }
    
    func fetchBankName(routingNumber: String) -> Observable<String> {
        return .error(ServiceError(serviceCode: ""))
    }
    
    func addBankAccount(_ bankAccount : BankAccount,
                        forCustomerNumber: String) -> Observable<WalletItemResult> {
        if forCustomerNumber == "13" { // Simulate duplicate payment
            return .error(ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue))
        } else {
            let walletResult = WalletItemResult(responseCode: 1, statusMessage: "pretty good", walletItemId: "123")
            return .just(walletResult)
        }
    }
    
    func addCreditCard(_ creditCard: CreditCard,
                       forCustomerNumber: String) -> Observable<WalletItemResult> {
        if forCustomerNumber == "13" { // Simulate duplicate payment
            return .error(ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue))
        } else {
            let walletResult = WalletItemResult(responseCode: 1, statusMessage: "pretty good", walletItemId: "123")
            return .just(walletResult)
        }
    }

    func updateCreditCard(walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String) -> Observable<Void> {
        return .error(ServiceError(serviceCode: ""))
    }

    func deletePaymentMethod(walletItem : WalletItem) -> Observable<Void> {
        return Observable.just(()).delay(1, scheduler: MainScheduler.instance)
    }

    func setOneTouchPayItem(walletItemId: String,
                            walletId: String?,
                            customerId: String) -> Observable<Void> {
        return .just(())
    }
    
    func removeOneTouchPayItem(customerId: String) -> Observable<Void> {
        return .just(())
    }
    
    func fetchWalletEncryptionKey(customerId: String, bankOrCard: BankOrCard, temporary: Bool, walletItemId: String? = nil) -> Observable<String> {
        return .just("")
    }
}
