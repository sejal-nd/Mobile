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
    ///
    /// - Parameters:
    ///   	- completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the WalletItem on success, or a ServiceError on failure.
    func fetchWalletItems() -> Observable<[WalletItem]>
    
    /// Fetch bank name through routing number
    ///
    /// - Parameters:
    ///     - routing number
    ///     - completion: the result contains the name of the bank that is determined by the routing number.
    func fetchBankName(routingNumber: String) -> Observable<String>
    
    
    /// Add a bank account to the users wallet.
    ///
    /// - Parameters:
    ///   - bankAccount: the account to add
    ///   - customerNumber: AccountsStore.shared.customerIdentifier
    ///   - completiong: the block to execute upon completion
    func addBankAccount(_ bankAccount: BankAccount, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult>
    
    
    /// Add a credit card to the users wallet.
    ///
    /// - Parameters:
    ///   - creditCard: the card to add
    ///   - customerNumber: AccountsStore.shared.customerIdentifier
    ///   - completion: the bock to execute upon completion
    func addCreditCard(_ creditCard: CreditCard, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult>
    
    
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
    ///		- completion: the block to execute upon completion, the ServiceResult
    ///       that is provided will contain nothing on success, or a ServiceError on failure.
    func deletePaymentMethod(walletItem: WalletItem) -> Observable<Void>
    
    
    /// Set a wallet item as the default/OneTouch payment method.
    ///
    /// - Parameters:
    ///   - walletItemId: the wallet item id to set
    ///   - walletId: the wallet id
    ///   - customerId: the custom number
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain nothing on success or a ServiceError on failure.
    func setOneTouchPayItem(walletItemId: String,
                            walletId: String?,
                            customerId: String) -> Observable<Void>
    
    
    /// Disable OneTouch Payment
    ///
    /// - Parameters:
    ///   - customerId: the customer number to disable one touch pay for
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain nothing on success or a ServiceError on failure.
    func removeOneTouchPayItem(customerId: String) -> Observable<Void>
}
