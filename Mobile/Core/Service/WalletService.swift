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
    func fetchWalletItems(completion: @escaping (_ result: ServiceResult<[WalletItem]>) -> Void)
    
    /// Fetch bank name through routing number
    ///
    /// - Parameters:
    ///     - routing number
    ///     - completion: the result contains the name of the bank that is determined by the routing number.
    func fetchBankName(routingNumber: String, completion: @escaping (_ result: ServiceResult<String>) -> Void)
    
    
    /// Add a bank account to the users wallet.
    ///
    /// - Parameters:
    ///   - bankAccount: the account to add
    ///   - customerNumber: AccountsStore.sharedInstance.customerIdentifier
    ///   - completiong: the block to execute upon completion
    func addBankAccount(_ bankAccount : BankAccount,
                        forCustomerNumber: String,
                        completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Void)
    
    
    /// Add a credit card to the users wallet.
    ///
    /// - Parameters:
    ///   - creditCard: the card to add
    ///   - customerNumber: AccountsStore.sharedInstance.customerIdentifier
    ///   - completion: the bock to execute upon completion
    func addCreditCard(_ creditCard: CreditCard,
                       forCustomerNumber: String,
                       completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Void)
    
    
    /// Update a credit card in the users wallet.
    ///
    /// - Parameters:
    ///   - walletItemId: the wallet item id to update
    ///   - customerNumber: AccountsStore.sharedInstance.customerIdentifier
    ///   - expirationMonth: the expiration month to set
    ///   - expirationYear: the expiration year to set
    ///   - securityCode: the security code to set
    ///   - postalCode: the postal code to set
    func updateCreditCard(_ walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String?,
                          expirationYear: String?,
                          securityCode: String?,
                          postalCode: String?,
                          nickname: String?,
                          completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    
    /// Update a bank account in the users wallet.
    ///
    /// - Parameters:
    ///   - walletItemID: the wallet item id to update
    ///   - bankAccountNumber: the new bank account number
    ///   - routingNumber: the routing number
    ///   - accountType: the account type
    ///   - nickname: the account nickname
    ///   - accountName; the account name
    func updateBankAccount(_ walletItemID: String,
                           bankAccountNumber: String,
                           routingNumber: String,
                           accountType: BankAccountType,
                           nickname: String?,
                           accountName: String?,
                           completion: @escaping (_ result: ServiceResult<Void>) -> Void)
    
    /// Delete wallet payment method.
    ///
    /// - Parameters:
    ///		- walletItemID
    ///		- completion: the block to execute upon completion, the ServiceResult
    ///       that is provided will contain nothing on success, or a ServiceError on failure.
    func deletePaymentMethod(_ walletItem : WalletItem,
                             completion: @escaping (_ result: ServiceResult<Void>) -> Void)
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to WalletService
extension WalletService {
    
    // Fetch for all three
    func fetchWalletItems() -> Observable<[WalletItem]> {
        return Observable.create { observer in
            self.fetchWalletItems(completion: { (result: ServiceResult<[WalletItem]>) in
                //
                switch result {
                case ServiceResult.Success(let walletItems):
                    observer.onNext(walletItems)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
    
    // Fetch bank name
    func fetchBankName(_ routingNumber: String) -> Observable<String> {
        return Observable.create { observer in
            self.fetchBankName(routingNumber: routingNumber, completion: { (result: ServiceResult<String>) in
                switch(result) {
                case ServiceResult.Success(let bankName):
                    observer.onNext(bankName)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func addBankAccount(_ bankAccount: BankAccount, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        return Observable.create { observer in
            self.addBankAccount(bankAccount, forCustomerNumber: customerNumber, completion: { (result: ServiceResult<WalletItemResult>) in
                switch(result) {
                case ServiceResult.Success(let walletItemResult):
                    observer.onNext(walletItemResult)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }

    func addCreditCard(_ creditCard: CreditCard, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        return Observable.create { observer in
            self.addCreditCard(creditCard, forCustomerNumber: customerNumber, completion: { (result: ServiceResult<WalletItemResult>) in
                switch(result) {
                case ServiceResult.Success(let walletItemResult):
                    observer.onNext(walletItemResult)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func updateCreditCard(_ walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String?,
                          expirationYear: String?,
                          securityCode: String?,
                          postalCode: String?,
                          nickname: String?) -> Observable<Void> {
    
        return Observable.create { observer in
            self.updateCreditCard(walletItemID,
                                  customerNumber: customerNumber,
                                  expirationMonth: expirationMonth,
                                  expirationYear: expirationYear,
                                  securityCode: securityCode,
                                  postalCode: postalCode,
                                  nickname: nickname,
                                  completion: { (result: ServiceResult<Void>) in
                                    //
                                    switch (result) {
                                    case ServiceResult.Success:
                                        observer.onNext()
                                        observer.onCompleted()
                                            
                                    case ServiceResult.Failure(let err):
                                        observer.onError(err)
                                    }
            })
            
            return Disposables.create()
        }
    }

    func updateBankAccount(_ walletItemID: String,
                           bankAccountNumber: String,
                           routingNumber: String,
                           accountType: BankAccountType,
                           nickname: String,
                           accountName: String) -> Observable<Void> {
        
        return Observable.create { observer in
            self.updateBankAccount(walletItemID,
                                  bankAccountNumber: bankAccountNumber,
                                  routingNumber: routingNumber,
                                  accountType: accountType,
                                  nickname: nickname,
                                  accountName: accountName,
                                  completion: { (result: ServiceResult<Void>) in
                                    //
                                    switch (result) {
                                    case ServiceResult.Success:
                                        observer.onNext()
                                        observer.onCompleted()
                                        
                                    case ServiceResult.Failure(let err):
                                        observer.onError(err)
                                    }
            })
            
            return Disposables.create()
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    // Delete Wallet for Comed/PECO
    func deletePaymentMethod(_ walletItem : WalletItem) -> Observable<Void> {
        return Observable.create { observer in
            self.deletePaymentMethod(walletItem,
                                     completion: { (result: ServiceResult<Void>) in
                switch (result) {
                case ServiceResult.Success:
                    observer.onNext()
                    observer.onCompleted()
                    
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            })
            
            return Disposables.create()
        }
    }
}
