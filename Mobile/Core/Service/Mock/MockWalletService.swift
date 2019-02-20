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
        let key = MockUser.current.currentAccount.dataKey(forFile: .wallet)
        return MockJSONManager.shared.rx.mappableArray(fromFile: .wallet, key: key)
    }
    
    func fetchBankName(routingNumber: String) -> Observable<String> {
        return .just("M&T Bank")
    }
    
    func addWalletItemMCS(_ walletItem: WalletItem) {
        // Do nothing - we never handle for the response of this
    }
    
    func updateWalletItemMCS(_ walletItem: WalletItem) {
        // Do nothing - we never handle for the response of this
    }

    func deletePaymentMethod(walletItem : WalletItem) -> Observable<Void> {
        return .just(())
    }

    func fetchWalletEncryptionKey(customerId: String,
                                  bankOrCard: BankOrCard,
                                  temporary: Bool,
                                  walletItemId: String? = nil) -> Observable<String> {
        return .just("")
    }
}
