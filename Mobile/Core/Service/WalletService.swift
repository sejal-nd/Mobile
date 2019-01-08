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
    
    
    /// Add a bank account to the users wallet.
    ///
    /// - Parameters:
    ///   - bankAccount: the account to add
    ///   - customerNumber: AccountsStore.shared.customerIdentifier
    func addBankAccount(_ bankAccount: BankAccount, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult>
    
    
    /// Add a credit card to the users wallet.
    ///
    /// - Parameters:
    ///   - creditCard: the card to add
    ///   - customerNumber: AccountsStore.shared.customerIdentifier
    func addCreditCard(_ creditCard: CreditCard, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult>
    
    
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
    
    /// Update a credit card in the users wallet.
    ///
    /// - Parameters:
    ///   - walletItemId: the wallet item id to update
    ///   - customerNumber: AccountsStore.shared.customerIdentifier
    ///   - expirationMonth: the expiration month to set
    ///   - expirationYear: the expiration year to set
    ///   - securityCode: the security code to set
    ///   - postalCode: the postal code to set
    func updateCreditCard(walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String) -> Observable<Void>
    
    /// Delete wallet payment method.
    ///
    /// - Parameters:
    ///		- walletItemID
    func deletePaymentMethod(walletItem: WalletItem) -> Observable<Void>
    
    
    /// Set a wallet item as the default/OneTouch payment method.
    ///
    /// - Parameters:
    ///   - walletItemId: the wallet item id to set
    ///   - walletId: the wallet id
    ///   - customerId: the custom number
    func setOneTouchPayItem(walletItemId: String,
                            walletId: String?,
                            customerId: String) -> Observable<Void>
    
    
    /// Disable OneTouch Payment
    ///
    /// - Parameters:
    ///   - customerId: the customer number to disable one touch pay for
    func removeOneTouchPayItem(customerId: String) -> Observable<Void>
    
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
