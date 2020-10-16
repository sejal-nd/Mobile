//
//  WalletService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 8/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt

extension WalletService: ReactiveCompatible {}

extension Reactive where Base == WalletService {
    static func fetchWalletItems() -> Observable<[WalletItem]> {
        return Observable<Wallet>.create { observer -> Disposable in
            WalletService.fetchWalletItems { observer.handle(result: $0) }
            return Disposables.create()
        }.map { $0.walletItems }
    }
    
    static func fetchBankName(routingNumber: String) -> Observable<String> {
        return Observable<BankName>.create { observer -> Disposable in
            WalletService.fetchBankName(routingNumber: routingNumber) { observer.handle(result: $0) }
            return Disposables.create()
        }.map { $0.value }
    }
    
    static func deletePaymentMethod(walletItem: WalletItem) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            WalletService.deletePaymentMethod(walletItem: walletItem) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func fetchWalletEncryptionKey(customerId: String,
                                  bankOrCard: BankOrCard,
                                  temporary: Bool,
                                  isWalletEmpty: Bool,
                                  walletItemId: String?) -> Observable<String> {
        return Observable.create { observer -> Disposable in
            WalletService.fetchWalletEncryptionKey(customerId: customerId, bankOrCard: bankOrCard, temporary: temporary, isWalletEmpty: isWalletEmpty, walletItemId: walletItemId) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
}
