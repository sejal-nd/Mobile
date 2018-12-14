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
        let opCo = Environment.shared.opco
        
        var params: Dictionary<String, String> = [:]
        
        if opCo == .comEd || opCo == .peco {
            params["biller_id"] = "\(opCo.rawValue)Registered"
        }
        
        return MCSApi.shared.post(path: "wallet/query", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let walletItems = dict["WalletItems"] as? [[String: Any]] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                let itemArray = walletItems.compactMap { WalletItem.from($0 as NSDictionary) }
                    .sorted { (a: WalletItem, b: WalletItem) in
                        // Sort order:
                        // 1. Default Payment Account (Paymentus Only)
                        // 2. Most recent to least recently added bank accounts
                        // 3. Most recent to least recently added credit cards
                        if Environment.shared.opco != .bge {
                            if a.isDefault && !b.isDefault {
                                return true
                            } else if b.isDefault && !a.isDefault {
                                return false
                            }
                        }

                        switch (a.bankOrCard, b.bankOrCard) {
                        case (.bank, .card):
                            return true
                        case (.card, .bank):
                            return false
                        case (.bank, .bank):
                            fallthrough
                        case (.card, .card):
                            guard let aCreated = a.dateCreated, let bCreated = b.dateCreated else {
                                return true
                            }
                            return aCreated >= bCreated
                        }
                }
                
                return itemArray
        }
    }
    
    func fetchBankName(routingNumber: String) -> Observable<String> {
        return MCSApi.shared.get(anon: true, path: "bank/" + routingNumber)
            .map { json in
                guard let dict = json as? [String: Any],
                    let bankName = dict["BankName"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return bankName
        }
    }
    
    //TODO: Remove this once BGE moves to paymentus
    func addBankAccount(_ bankAccount: BankAccount, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        switch Environment.shared.opco {
        case .comEd, .peco:
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        case .bge:
            return addMCSBankAccount(bankAccount)
        }
    }
    
    //TODO: Remove this once BGE moves to paymentus
    private func addMCSBankAccount(_ bankAccount: BankAccount) -> Observable<WalletItemResult> {
        let params = ["account_number" : AccountsStore.shared.accounts[0].accountNumber,
                      "routing_number" : bankAccount.routingNumber,
                      "account_nick_name" : bankAccount.accountNickname ?? "",
                      "bank_account_type" : bankAccount.accountType ?? "",
                      "bank_account_number" : bankAccount.bankAccountNumber,
                      "bank_account_name" : bankAccount.accountName ?? ""] as [String:Any]
        
        return MCSApi.shared.post(path: "wallet", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let message = dict["message"] as? String,
                    let walletItemId = dict["walletItemID"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return WalletItemResult(responseCode: 0, statusMessage: message, walletItemId: walletItemId)
            }
            .catchError { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                if let speedpayError = SpeedpayErrorMapper.shared.getError(message: serviceError.errorDescription ?? "", context: nil) {
                    if speedpayError.id == "28003" { // Duplicate
                        throw ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue)
                    } else {
                        throw ServiceError(serviceMessage: speedpayError.text)
                    }
                } else {
                    if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                        throw serviceError
                    } else {
                        throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                    }
                }
        }
    }
    
    //TODO: Remove this once BGE moves to paymentus
    func addCreditCard(_ creditCard: CreditCard, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        switch Environment.shared.opco {
        case .comEd, .peco:
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        case .bge:
            return addCreditCardSpeedpay(creditCard)
        }
    }
    
    //TODO: Remove this once BGE moves to paymentus
    private func addCreditCardSpeedpay(_ creditCard: CreditCard) -> Observable<WalletItemResult> {
        return SpeedpayApi().fetchTokenizedCardNumber(cardNumber: creditCard.cardNumber)
            .flatMap { [weak self] token in
                return self?.addCreditCardMCS(creditCard, token: token) ?? .empty()
        }
    }
    
    //TODO: Remove this once BGE moves to paymentus
    private func addCreditCardMCS(_ creditCard: CreditCard, token: String) -> Observable<WalletItemResult> {
        let parsed = DateFormatter.MMyyyyFormatter.date(from: creditCard.expirationMonth + creditCard.expirationYear)

        let params = ["account_number": AccountsStore.shared.accounts[0].accountNumber,
                      "account_nick_name": creditCard.nickname ?? "",
                      "bank_account_type" : "card",
                      "bank_account_number" : token,
                      "bank_account_name" : "card",
                      "zipcode" : creditCard.postalCode,
                      "cvv" : creditCard.securityCode,
                      "expiration_date" : DateFormatter.yyyyMMddFormatter.string(from: parsed!)] as [String: Any]
        
        return MCSApi.shared.post(path: "wallet", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let message = dict["message"] as? String,
                    let walletItemId = dict["walletItemID"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return WalletItemResult(responseCode: 0, statusMessage: message, walletItemId: walletItemId)
            }
            .catchError { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                if let speedpayError = SpeedpayErrorMapper.shared.getError(message: serviceError.errorDescription ?? "", context: nil) {
                    if speedpayError.id == "28003" { // Duplicate
                        throw ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue)
                    } else {
                        throw ServiceError(serviceMessage: speedpayError.text)
                    }
                } else {
                    if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                        throw serviceError
                    } else {
                        throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                    }
                }
        }
    }
    
    //TODO: Remove this once BGE moves to paymentus
    /// "Add" a wallet item to MCS - This should be called after
    /// adding a wallet item through a third party (Speedpay)
    ///
    /// - Parameters:
    ///   - accountNumber: the user account number
    ///   - maskedAccountNumber: the masked (last 4 digits) of the wallet item account number
    ///   - categoryType: the payment category type that was added.
    private func addWalletItemMCS(accountNumber: String, maskedAccountNumber: String, categoryType: String) {
        let params: [String: Any] = ["account_number" : accountNumber,
                                     "masked_wallet_item_acc_num" : maskedAccountNumber,
                                     "payment_category_type" : categoryType]
        
        MCSApi.shared.post(path: "wallet", params: params)
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    //TODO: Remove this once BGE moves to paymentus
    func updateCreditCard(walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String) -> Observable<Void> {
        switch Environment.shared.opco {
        case .comEd, .peco:
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        case .bge:
            return updateMCSCreditCard(walletItemID: walletItemID,
                                       expirationMonth: expirationMonth,
                                       expirationYear: expirationYear,
                                       securityCode: securityCode,
                                       postalCode: postalCode)
        }
        
    }
    
    private func updateMCSCreditCard(walletItemID: String,
                                     expirationMonth: String,
                                     expirationYear: String,
                                     securityCode: String,
                                     postalCode: String) -> Observable<Void> {
        var params = ["account_number": AccountsStore.shared.accounts[0].accountNumber,
                      "wallet_item_id": walletItemID,
                      "bank_account_type": "card",
                      "zipcode": postalCode,
                      "cvv": securityCode] as [String: Any]

        if let parsed = DateFormatter.MMyyyyFormatter.date(from: expirationMonth + expirationYear) {
            params["expiration_date"] = DateFormatter.yyyyMMddFormatter.string(from: parsed)
        }
        
        return MCSApi.shared.put(path: "wallet", params: params)
            .mapTo(())
            .catchError { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                if let speedpayError = SpeedpayErrorMapper.shared.getError(message: serviceError.errorDescription ?? "", context: nil) {
                    if speedpayError.id == "28003" { // Duplicate
                        throw ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue)
                    } else {
                        throw ServiceError(serviceMessage: speedpayError.text)
                    }
                } else {
                    if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                        throw serviceError
                    } else {
                        throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                    }
                }
        }
    }
    
    func updateMCSBankAccount(walletItemID: String,
                              bankAccountNumber: String,
                              routingNumber: String,
                              accountType: BankAccountType,
                              nickname: String?,
                              accountName: String?) -> Observable<Void> {
        var params = ["wallet_item_id": walletItemID,
                      "account_number": AccountsStore.shared.accounts[0].accountNumber,
                      "routing_number": routingNumber,
                      "bank_account_type": accountType.rawValue,
                      "bank_account_number": bankAccountNumber] as [String : Any]
        
        if(!(nickname ?? "").isEmpty) {
            params["account_nick_name"] = nickname
        }
        if(!(accountName ?? "").isEmpty) {
            params["bank_account_name"] = accountName
        }
        
        return MCSApi.shared.put(path: "wallet", params: params)
            .mapTo(())
    }
    
    func deletePaymentMethod(walletItem : WalletItem) -> Observable<Void> {
        var params = ["account_number": AccountsStore.shared.accounts[0].accountNumber,
                      "wallet_item_id": walletItem.walletItemID ?? ""] as [String: Any]
        
        let opCo = Environment.shared.opco
        if opCo == .comEd || opCo == .peco {
            params["biller_id"] = "\(opCo.rawValue)Registered"
            params["payment_category_type"] = walletItem.paymentCategoryType?.rawValue
        }
        
        return MCSApi.shared.post(path: "wallet/delete", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            })
            .catchError { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                if Environment.shared.opco == .bge {
                    if let speedpayError = SpeedpayErrorMapper.shared.getError(message: serviceError.errorDescription ?? "", context: nil) {
                        throw ServiceError(serviceMessage: speedpayError.text)
                    } else {
                        if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                            throw serviceError
                        } else {
                            throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                        }
                    }
                } else {
                    throw serviceError
                }
            }
    }
    
    func setOneTouchPayItem(walletItemId: String, walletId: String?, customerId: String) -> Observable<Void> {
        let params = ["wallet_item_id":walletItemId,
                      "wallet_id":walletId ?? "",
                      "person_id":customerId]
        
        return MCSApi.shared.put(path: "wallet/default", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            })
    }
    
    func removeOneTouchPayItem(customerId: String) -> Observable<Void> {
        return MCSApi.shared.delete(path: "wallet/default/\(customerId)", params: nil)
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
        
        var strParam = "pageView=mobile;postMessagePmDetailsOrigin=https://exeloncorp.com;"
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
        
        return MCSApi.shared.post(path: "encryptionkey", params: params)
            .map { json in
                guard let token = json as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return token
            }
    }
}
