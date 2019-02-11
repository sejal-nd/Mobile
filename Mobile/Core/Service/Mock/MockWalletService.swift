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
                WalletItem(nickName: "Expired Card", isDefault: false, bankOrCard: .card)
            ]
        } else if loggedInUsername == "billCardWithExpiredDefaultPayment" {
            walletItems = [
                WalletItem(nickName: "Expired Card", expirationDate: "01/2018", isDefault: true, bankOrCard: .card)
            ]
        }else if loggedInUsername == "billCardWithDefaultCcPayment" {
            walletItems = [
                WalletItem(nickName: "Test Nickname", isDefault: true,  bankOrCard: .card),
            ]
        } else if AccountsStore.shared.currentAccount.accountNumber == "13" { // Set this to test no OTP items
            walletItems = [
                WalletItem(nickName: "Test Nickname", bankOrCard: .card),
                WalletItem(nickName: "Test Nickname 2", bankOrCard: .card)
            ]
        } else {
            walletItems = [
                WalletItem(nickName: "Test Nickname"),
                WalletItem(nickName: "Test Nickname 2", isDefault: true,  bankOrCard: .card)
            ]
        }

        return Observable.just(walletItems).delay(1, scheduler: MainScheduler.instance)
    }
    
    func fetchBankName(routingNumber: String) -> Observable<String> {
        return .error(ServiceError(serviceCode: ""))
    }
    
    func addWalletItemMCS(_ walletItem: WalletItem) {
        // Do nothing - we never handle for the response of this
    }
    
    func updateWalletItemMCS(_ walletItem: WalletItem) {
        // Do nothing - we never handle for the response of this
    }

    func deletePaymentMethod(walletItem : WalletItem) -> Observable<Void> {
        return Observable.just(()).delay(1, scheduler: MainScheduler.instance)
    }

    func fetchWalletEncryptionKey(customerId: String, bankOrCard: BankOrCard, temporary: Bool, walletItemId: String? = nil) -> Observable<String> {
        return .just("")
    }
}
