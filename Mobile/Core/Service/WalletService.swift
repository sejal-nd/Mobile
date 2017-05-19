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
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain the AccountDetails on success, or a ServiceError on failure.

    func fetchWalletItems(completion: @escaping (_ result: ServiceResult<[WalletItem]>) -> Void)
    
    /// Create wallet payment method (Comed/PECO/BGE) information.
    ///
    /// - Parameters:
    ///   - accountNumber
    ///   - maskedWalletItem
    ///   - paymentCategory
    ///   - completion: the block to execute upon completion, the ServiceResult
    ///     that is provided will contain nothing on success, or a ServiceError on failure.
    
	func createWalletPaymentMethod(_ paymentCategory: PaymentCategoryType,
	                               routingNumber: String,
	                               accountNickName: String,
	                               bankAccountType: BankAccountType,
	                               bankAccountNumber: String,
	                               bankAccountName: String,
	                               completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
	/// Update wallet payment method (Comed/PECO/BGE) information.
	///
	/// - Parameters:
	///   - accountNumber
	///   - walletItemID
	///   - maskedWalletItemAccountNumber
	///	  - paymentCategoryType
	///   - completion: the block to execute upon completion, the ServiceResult
	///     that is provided will contain nothing on success, or a ServiceError on failure.
	
	func updateWalletPaymentMethod(_ paymentCategoryType: PaymentCategoryType,
	                               walletItemID: String,
	                               routingNumber: String,
	                               accountNickName: String,
	                               bankAccountType: BankAccountType,
	                               bankAccountNumber: String,
	                               bankAccountName: String,
	                               completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
	/// Delete wallet payment method (Comed/PECO) information.
	///
	/// - Parameters:
	///		- accountNumber
	///		- maskedWalletItemAccountNumber
	///		- paymentCategoryType
	///		- walletItemID
	///		- billerID
	///		- completion: the block to execute upon completion, the ServiceResult
	///       that is provided will contain nothing on success, or a ServiceError on failure.
	func deletePaymentMethod(_ paymentCategoryType: PaymentCategoryType,
	                         walletItemID: String,
	                         billerID: String,
	                         completion: @escaping (_ result: ServiceResult<Void>) -> Void)
	
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Reactive Extension to WalletService
extension WalletService {
	
	// Fetch for all three
    func fetchWalletItems() -> Observable<[WalletItem]> {
        return Observable.create { observer in
            self.fetchWalletItems { (result: ServiceResult<[WalletItem]>) in
                switch result {
                case ServiceResult.Success(let walletItem):
                    observer.onNext(walletItem)
                    observer.onCompleted()
                case ServiceResult.Failure(let err):
                    observer.onError(err)
                }
            }
            
            return Disposables.create()
        }
    }

	
	/////////////////////////////////////////////////////////////////////////////////////////////////
    // Create Wallet for Comed/PECO/BGE
	func createWalletPaymentMethod(_ paymentCategory: PaymentCategoryType,
	                               routingNumber: String,
	                               accountNickName: String,
	                               bankAccountType: BankAccountType,
	                               bankAccountNumber: String,
	                               bankAccountName: String) -> Observable<Void> {
        //
        return Observable.create { observer in
            self.createWalletPaymentMethod(paymentCategory,
                                           routingNumber: routingNumber,
                                           accountNickName: accountNickName,
                                           bankAccountType: bankAccountType,
                                           bankAccountNumber: bankAccountNumber,
                                           bankAccountName: bankAccountName,
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
	// Update Wallet for Comed/PECO
	func updateWalletPaymentMethod(_ paymentCategoryType: PaymentCategoryType,
	                               walletItemID: String,
	                               routingNumber: String,
	                               accountNickName: String,
	                               bankAccountType: BankAccountType,
	                               bankAccountNumber: String,
	                               bankAccountName: String) -> Observable<Void> {
		//
		return Observable.create { observer in
			self.updateWalletPaymentMethod(paymentCategoryType,
			                               walletItemID: walletItemID,
			                               routingNumber: routingNumber,
			                               accountNickName: accountNickName,
			                               bankAccountType: bankAccountType,
			                               bankAccountNumber: bankAccountNumber,
			                               bankAccountName: bankAccountName,
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
	func deletePaymentMethod(_ paymentCategoryType: PaymentCategoryType,
	                         walletItemID: String,
	                         billerID: String) -> Observable<Void> {
		//
		return Observable.create { observer in
			self.deletePaymentMethod(paymentCategoryType,
			                         walletItemID: walletItemID,
			                         billerID: billerID,
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
}
