//
//  WalletService.swift
//  BGE
//
//  Created by Cody Dillon on 8/6/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

struct WalletService {
    static func fetchWalletItems(completion: @escaping (Result<Wallet, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .wallet(), completion: completion)
    }
    
    static func fetchBankName(routingNumber: String, completion: @escaping (Result<BankName, NetworkingError>) -> ()) {
        NetworkingLayer.request(router: .bankName(routingNumber: routingNumber), completion: completion)
    }
    
    static func addWalletItem(_ walletItem: WalletItem, completion: ((Result<VoidDecodable, NetworkingError>) -> ())? = nil) {
        let request = WalletItemRequest(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                        maskedAccountNumber: walletItem.maskedAccountNumber ?? "",
                                        paymentCategoryType: walletItem.categoryType)
        
        NetworkingLayer.request(router: .addWalletItem(request: request)) { result in
            completion?(result)
        }
    }
    
    static func updateWalletItem(_ walletItem: WalletItem, completion: ((Result<VoidDecodable, NetworkingError>) -> ())? = nil) {
        let request = WalletItemRequest(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                        maskedAccountNumber: walletItem.maskedAccountNumber ?? "",
                                        paymentCategoryType: walletItem.categoryType)
        
        NetworkingLayer.request(router: .updateWalletItem(request: request)) { result in
            completion?(result)
        }
    }
    
    static func deletePaymentMethod(walletItem: WalletItem, completion: @escaping (Result<VoidDecodable, NetworkingError>) -> ()) {
        let request = WalletItemDeleteRequest(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                              walletItemId: walletItem.walletItemId ?? "",
                                              maskedAccountNumber: walletItem.maskedAccountNumber ?? "",
                                              billerId: AccountsStore.shared.billerID,
            paymentCategoryType: walletItem.categoryType)
        
        NetworkingLayer.request(router: .deleteWalletItem(request: request), completion: completion)
    }
    
    static func fetchWalletEncryptionKey(customerId: String,
                                  bankOrCard: BankOrCard,
                                  temporary: Bool,
                                  isWalletEmpty: Bool,
                                  walletItemId: String? = nil, completion: @escaping (Result<StringResult, NetworkingError>) -> ()) {
        
        var strParam = "pageView=mobile;postMessagePmDetailsOrigin=\(Environment.shared.paymentusUrl);"
        if temporary {
            strParam += "nickname=false;primaryPM=false;"
        } else {
            if isWalletEmpty { // If wallet is empty, hide the default checkbox because Paymentus automatically sets first wallet items as default
                strParam += "primaryPM=false;"
            }
        }
        
        let ownerId: String? = !temporary ? customerId : nil
        let request = WalletEncryptionKeyRequest(pmCategory: bankOrCard == .bank ? "DD" : "CC", postbackUrl: "", ownerId: ownerId, strParam: strParam, walletItemId: walletItemId)
        
        NetworkingLayer.request(router: .walletEncryptionKey(request: request), completion: completion)
    }
}
