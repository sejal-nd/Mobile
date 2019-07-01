//
//  WalletService.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol WalletService {
    /// Fetch wallet items detailed information.
    func fetchWalletItems() -> Observable<[WalletItem]>
    
    /// Fetch bank name through routing number
    func fetchBankName(routingNumber: String) -> Observable<String>
    
    /// "Add" a wallet item to MCS - this should be called after
    /// adding a wallet item through a third party (Paymentus) to trigger
    /// the sending of a confirmation email
    ///
    /// - Parameters:
    ///   - walletItem: the WalletItem that was added
    ///
    /// Void function because we do not rely on the response to this, we simply fire it
    /// off and forget it
    func addWalletItemMCS(_ walletItem: WalletItem)
    
    /// "Update" a wallet item to MCS - this should be called after
    /// editing a wallet item through a third party (Paymentus) to trigger
    /// the sending of a confirmation email
    ///
    /// - Parameters:
    ///   - walletItem: the WalletItem that was added
    ///
    /// Void function because we do not rely on the response to this, we simply fire it
    /// off and forget it
    func updateWalletItemMCS(_ walletItem: WalletItem)
    
    /// Delete wallet payment method.
    ///
    /// - Parameters:
    ///		- walletItemID
    func deletePaymentMethod(walletItem: WalletItem) -> Observable<Void>
    
    /// Generates the encryption key to pass to the Paymentus iFrame
    func fetchWalletEncryptionKey(customerId: String,
                                  bankOrCard: BankOrCard,
                                  temporary: Bool,
                                  isWalletEmpty: Bool,
                                  walletItemId: String?) -> Observable<String>
}

extension WalletService {
    func fetchWalletEncryptionKey(customerId: String,
                                  bankOrCard: BankOrCard,
                                  temporary: Bool,
                                  isWalletEmpty: Bool,
                                  walletItemId: String? = nil) -> Observable<String> {
        return fetchWalletEncryptionKey(customerId: customerId,
                                        bankOrCard: bankOrCard,
                                        temporary: temporary,
                                        isWalletEmpty: isWalletEmpty,
                                        walletItemId: walletItemId)
    }
}
