//
//  MCSWalletService.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MCSWalletService: WalletService {
    let disposeBag = DisposeBag()
    
    func fetchWalletItems() -> Observable<[WalletItem]> {
        let params = ["biller_id": "\(Environment.shared.opco.rawValue)Registered"]
        return MCSApi.shared.post(pathPrefix: .auth, path: "wallet/query", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let walletItems = dict["WalletItems"] as? [[String: Any]] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                let itemArray = walletItems.compactMap { WalletItem.from($0 as NSDictionary) }
                    .sorted { (a: WalletItem, b: WalletItem) in
                        // Sort order:
                        // 1. Default Payment Method
                        // 2. Most recent to least recently added bank accounts
                        // 3. Most recent to least recently added credit cards
                        if a.isDefault && !b.isDefault {
                            return true
                        } else if b.isDefault && !a.isDefault {
                            return false
                        }

                        switch (a.bankOrCard, b.bankOrCard) {
                        case (.bank, .card):
                            return true
                        case (.card, .bank):
                            return false
                        case (.bank, .bank):
                            fallthrough
                        case (.card, .card):
                            return true
                        }
                }
                
                return itemArray
            }
    }
    
    func fetchBankName(routingNumber: String) -> Observable<String> {
        return MCSApi.shared.get(pathPrefix: .anon, path: "bank/" + routingNumber)
            .map { json in
                guard let dict = json as? [String: Any],
                    let bankName = dict["BankName"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return bankName
            }
    }
    
    func addWalletItemMCS(_ walletItem: WalletItem) {
        if Environment.shared.opco == .bge { return } // ComEd/PECO only
        
        let params: [String: Any] = [
            "account_number": AccountsStore.shared.currentAccount.accountNumber,
            "masked_wallet_item_acc_num": walletItem.maskedWalletItemAccountNumber ?? "",
            "payment_category_type": walletItem.bankOrCard == .bank ? "check" : "credit"
        ]
        
        /* We don't dispose this observable because we want the request to live on
         * even after we've popped the PaymentusFormViewController */
        _ = MCSApi.shared.post(pathPrefix: .auth, path: "wallet", params: params).subscribe()
    }
    
    func updateWalletItemMCS(_ walletItem: WalletItem) {
        if Environment.shared.opco == .bge { return } // ComEd/PECO only
        
        let params: [String: Any] = [
            "account_number": AccountsStore.shared.currentAccount.accountNumber,
            "masked_wallet_item_acc_num": walletItem.maskedWalletItemAccountNumber ?? "",
            "payment_category_type": walletItem.bankOrCard == .bank ? "check" : "credit"
        ]
        
        /* We don't dispose this observable because we want the request to live on
         * even after we've popped the PaymentusFormViewController */
        _ = MCSApi.shared.put(pathPrefix: .auth, path: "wallet", params: params).subscribe()
    }
    
    func deletePaymentMethod(walletItem : WalletItem) -> Observable<Void> {
        let opCo = Environment.shared.opco
        let params: [String: Any] = [
            "account_number": AccountsStore.shared.accounts[0].accountNumber,
            "wallet_item_id": walletItem.walletItemId ?? "",
            "masked_wallet_item_acc_num": walletItem.maskedWalletItemAccountNumber ?? "",
            "biller_id": "\(opCo.rawValue)Registered",
            "payment_category_type": walletItem.bankOrCard == .bank ? "check" : "credit"
        ]
        
        return MCSApi.shared.post(pathPrefix: .auth, path: "wallet/delete", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            })
    }
    
    func fetchWalletEncryptionKey(customerId: String,
                                  bankOrCard: BankOrCard,
                                  temporary: Bool,
                                  isWalletEmpty: Bool,
                                  walletItemId: String? = nil) -> Observable<String> {
        var params = [
            "pmCategory": bankOrCard == .bank ? "DD" : "CC", // "DC" = Debit Card
            "postbackUrl": "",
        ]
        
        var strParam = "pageView=mobile;postMessagePmDetailsOrigin=\(Environment.shared.mcsConfig.paymentusUrl);"
        if temporary {
            strParam += "nickname=false;primaryPM=false;"
        } else {
            if isWalletEmpty { // If wallet is empty, hide the default checkbox because Paymentus automatically sets first wallet items as default
                strParam += "primaryPM=false;"
            }
            params["ownerId"] = customerId
        }
        params["strParam"] = strParam
        
        if let wid = walletItemId { // Indicates that this is an edit operation (as opposed to an add)
            params["wallet_item_id"] = wid
        }
        
        return MCSApi.shared.post(pathPrefix: .auth, path: "encryptionkey", params: params)
            .map { json in
                guard let token = json as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return token
            }
    }
}
