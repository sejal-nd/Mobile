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
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet/query", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let walletItems = dict["WalletItems"] as? [[String: Any]] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                let itemArray = walletItems.compactMap { WalletItem.from($0 as NSDictionary) }
                    .sorted { (a: WalletItem, b: WalletItem) in
                        switch (a.bankOrCard, b.bankOrCard) {
                        case (.bank, .bank):
                            guard let aCreated = a.dateCreated, let bCreated = b.dateCreated else {
                                return true
                            }
                            return aCreated >= bCreated
                        case (.bank, .card):
                            return true
                        case (.card, .bank):
                            return false
                        case (.card, .card):
                            return true
                        }
                }
                
                return itemArray
        }
    }
    
    func fetchAuthSessionToken() -> Observable<String> {
        let opCo = Environment.shared.opco
        
        var params: Dictionary<String, String> = [:]
        
        if opCo == .comEd || opCo == .peco {
            params["biller_id"] = "\(opCo.rawValue)Registered"
        }
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet/query", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let token = dict["authSessionToken"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.localError.rawValue,
                                           serviceMessage: "An authentication error has occurred.")
                }
                
                return token
        }
    }
    
    func fetchBankName(routingNumber: String) -> Observable<String> {
        let opCo = Environment.shared.opco.displayString.uppercased()
        let path = "anon_\(MCSApi.API_VERSION)/" + opCo + "/bank/" + routingNumber
        return MCSApi.shared.get(path: path)
            .map { json in
                guard let dict = json as? [String: Any],
                    let bankName = dict["BankName"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return bankName
        }
    }
    
    func addBankAccount(_ bankAccount: BankAccount, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        let opCo = Environment.shared.opco
        
        if(opCo == .comEd || opCo == .peco) {
            return addFiservBankAccount(bankAccount, forCustomerNumber: customerNumber)
        } else {
            return addMCSBankAccount(bankAccount)
        }
    }
    
    private func addFiservBankAccount(_ bankAccount: BankAccount, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        //1. get the wallet to grab a new auth token for fiserv
        //2. call the fiserv add api
        
        let opCo = Environment.shared.opco
        
        var params: Dictionary<String, String> = [:]
        
        if opCo == .comEd || opCo == .peco {
            params["biller_id"] = "\(opCo.rawValue)Registered"
        }
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet/query", params: params)
            .flatMap { json -> Observable<WalletItemResult> in
                guard let dict = json as? [String: Any],
                    let token = dict["authSessionToken"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.localError.rawValue,
                                           serviceMessage: "An authentication error has occurred.")
                }
                
                return FiservApi().addBankAccount(bankAccountNumber: bankAccount.bankAccountNumber,
                                                  routingNumber: bankAccount.routingNumber,
                                                  firstName: nil,
                                                  lastName: nil,
                                                  nickname: bankAccount.accountNickname,
                                                  token: token,
                                                  customerNumber: customerNumber,
                                                  oneTimeUse: bankAccount.oneTimeUse)
            }
            .do(onNext: { [weak self] _ in
                let accountNumber = bankAccount.bankAccountNumber
                let last4 = accountNumber[accountNumber.index((accountNumber.endIndex), offsetBy: -4)...]
                
                self?.addWalletItemMCS(accountNumber: AccountsStore.shared.accounts[0].accountNumber,
                                       maskedAccountNumber: String(last4),
                                       categoryType: "Checking")
            })
    }
    
    private func addMCSBankAccount(_ bankAccount: BankAccount) -> Observable<WalletItemResult> {
        let params = ["account_number" : AccountsStore.shared.accounts[0].accountNumber,
                      "routing_number" : bankAccount.routingNumber,
                      "account_nick_name" : bankAccount.accountNickname ?? "",
                      "bank_account_type" : bankAccount.accountType ?? "",
                      "bank_account_number" : bankAccount.bankAccountNumber,
                      "bank_account_name" : bankAccount.accountName ?? ""] as [String:Any]
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet", params: params)
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
    
    func addCreditCard(_ creditCard: CreditCard, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        switch Environment.shared.opco {
        case .comEd, .peco:
            return addCreditCardFiserv(creditCard, forCustomerNumber: customerNumber)
        case .bge:
            return addCreditCardSpeedpay(creditCard)
        }
    }
    
    private func addCreditCardFiserv(_ creditCard: CreditCard, forCustomerNumber customerNumber: String) -> Observable<WalletItemResult> {
        var params: Dictionary<String, String> = [:]
        params["biller_id"] = "\(Environment.shared.opco.rawValue)Registered"
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet/query", params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let token = dict["authSessionToken"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.localError.rawValue,
                                           serviceMessage: "An authentication error has occurred.")
                }
                
                return token
            }
            .flatMap { token in
                FiservApi().addCreditCard(cardNumber: creditCard.cardNumber,
                                          expirationMonth: creditCard.expirationMonth,
                                          expirationYear: creditCard.expirationYear,
                                          securityCode: creditCard.securityCode,
                                          postalCode: creditCard.postalCode,
                                          nickname: creditCard.nickname,
                                          token: token,
                                          customerNumber: customerNumber,
                                          oneTimeUse: creditCard.oneTimeUse)
                    .do(onNext: { [weak self] walletItemResult in
                        let string = creditCard.cardNumber
                        let last4 = string[string.index(string.endIndex, offsetBy: -4)...]
                        
                        self?.addWalletItemMCS(accountNumber: AccountsStore.shared.accounts[0].accountNumber,
                                              maskedAccountNumber: String(last4),
                                              categoryType: "Credit")
                    })
        }
    }
    
    private func addCreditCardSpeedpay(_ creditCard: CreditCard) -> Observable<WalletItemResult> {
        return SpeedpayApi().fetchTokenizedCardNumber(cardNumber: creditCard.cardNumber)
            .flatMap { [weak self] token in
                return self?.addCreditCardMCS(creditCard, token: token) ?? .empty()
        }
    }
    
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
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet", params: params)
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
    
    /// "Add" a wallet item to MCS - This should be called after
    /// adding a wallet item through a third party (Fiserv/Speedpay)
    ///
    /// - Parameters:
    ///   - accountNumber: the user account number
    ///   - maskedAccountNumber: the masked (last 4 digits) of the wallet item account number
    ///   - categoryType: the payment category type that was added.
    private func addWalletItemMCS(accountNumber: String, maskedAccountNumber: String, categoryType: String) {
        let params: [String: Any] = ["account_number" : accountNumber,
                                     "masked_wallet_item_acc_num" : maskedAccountNumber,
                                     "payment_category_type" : categoryType]
        
        MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet", params: params)
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    func updateCreditCard(walletItemID: String,
                          customerNumber: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String) -> Observable<Void> {
        switch Environment.shared.opco {
        case .comEd, .peco:
            return updateFiservCreditCard(walletItemID: walletItemID,
                                          customerNumber: customerNumber,
                                          expirationMonth: expirationMonth,
                                          expirationYear: expirationYear,
                                          securityCode: securityCode,
                                          postalCode: postalCode)
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
        
        return MCSApi.shared.put(path: "auth_\(MCSApi.API_VERSION)/wallet", params: params)
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
    
    private func updateFiservCreditCard(walletItemID: String,
                                        customerNumber: String,
                                        expirationMonth: String,
                                        expirationYear: String,
                                        securityCode: String,
                                        postalCode: String) -> Observable<Void> {
        
        var params: [String: Any] = [:]
        switch Environment.shared.opco {
        case .comEd, .peco:
            params["biller_id"] = "\(Environment.shared.opco.rawValue)Registered"
        case .bge:
            break
        }
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet/query", params: params)
            .flatMap { json -> Observable<WalletItemResult> in
                guard let dict = json as? [String: Any],
                    let token = dict["authSessionToken"] as? String else {
                        throw ServiceError(serviceCode: ServiceErrorCode.localError.rawValue,
                                           serviceMessage: "An authentication error has occurred.")
                }
                
                return FiservApi().updateCreditCard(walletItemID: walletItemID,
                                                    expirationMonth: expirationMonth,
                                                    expirationYear: expirationYear,
                                                    securityCode: securityCode,
                                                    postalCode: postalCode,
                                                    token: token,
                                                    customerNumber: customerNumber)
            }
            .mapTo(())
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                // Send the PUT request to auth_\(MCSApi.API_VERSION)/wallet so that emails get sent out - ignoring whether it succeeds to fails
                self.updateMCSCreditCard(walletItemID: walletItemID,
                                         expirationMonth: expirationMonth,
                                         expirationYear: expirationYear,
                                         securityCode: securityCode,
                                         postalCode: postalCode)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            })
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
        
        return MCSApi.shared.put(path: "auth_\(MCSApi.API_VERSION)/wallet", params: params)
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
        
        return MCSApi.shared.post(path: "auth_\(MCSApi.API_VERSION)/wallet/delete", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            })
            .catchError { err in
                guard let error = err as? ServiceError else {
                    throw ServiceError(cause: err)
                }
                
                if let fiservError = FiservErrorMapper.shared.getError(message: error.errorDescription ?? "", context: nil) {
                    throw ServiceError(serviceMessage: fiservError.text)
                } else if let speedpayError = SpeedpayErrorMapper.shared.getError(message: error.errorDescription ?? "", context: nil) {
                    throw ServiceError(serviceMessage: speedpayError.text)
                } else {
                    if error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                        throw err
                    } else {
                        throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                    }
                }
        }
    }
    
    func setOneTouchPayItem(walletItemId: String, walletId: String?, customerId: String) -> Observable<Void> {
        let params = ["wallet_item_id":walletItemId,
                      "wallet_id":walletId ?? "",
                      "person_id":customerId]
        
        return MCSApi.shared.put(path: "auth_\(MCSApi.API_VERSION)/wallet/default", params: params)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            })
    }
    
    func removeOneTouchPayItem(customerId: String) -> Observable<Void> {
        return MCSApi.shared.delete(path: "auth_\(MCSApi.API_VERSION)/wallet/default/\(customerId)", params: nil)
            .mapTo(())
            .do(onNext: {
                RxNotifications.shared.defaultWalletItemUpdated.onNext(())
            })
    }
    
    func fetchWalletEncryptionKey(customerId: String, bankOrCard: BankOrCard, postbackUrl: String, walletItemId: String? = nil) -> Observable<String> {
        let opco = Environment.shared.opco.displayString.uppercased()
        let anonPath = "anon_\(MCSApi.API_VERSION)/\(opco)/encryptionkey"
        let authPath = "auth_\(MCSApi.API_VERSION)/encryptionkey"
        var params = [
            "pmCategory": bankOrCard == .bank ? "DD" : "CC", // "DC" = Debit Card
            "ownerId": customerId,
            "postbackUrl": postbackUrl,
        ]
        if let wid = walletItemId { // Indicates that this is an edit operation (as opposed to an add)
            params["wallet_item_id"] = wid
        }
        return MCSApi.shared.post(path: anonPath, params: params)
            .map { json in
                guard let dict = json as? [String: Any],
                    let token = dict["Token"] as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                return token
            }
    }
}
