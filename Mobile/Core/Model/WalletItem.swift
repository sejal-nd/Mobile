//
//  Wallet.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper


/* WalletItem:: (Comed/PECO)
 
 "walletItemID": "2487071",
 "walletExternalID": "226734",
 "maskedWalletItemAccountNumber": "6789",
 "nickName": "6789",
 "walletItemStatusType": "Registered",
 "paymentCategoryType": "Check",
 "paymentMethodType": "ACH"
 
 */

/* WalletItem:: (BGE)
 
 "walletItemID": "dbk:15xNk4+rK4T7UZiO2eFzxM9STu81LqRqd133rgVkC58=",
 "nickName": "from POSTMAN",
 "maskedWalletItemAccountNumber": "0987",
 "walletItemStatusType": "pnd_active",
 "bankAccountType": "checking",
 "flagnocViewed": "true",
 "bankAccountNumber": "876543210987",
 "bankAccountName": "test account"
 
 */

enum WalletItemStatusType: String {
    case suspended = "Suspended"
    case expired = "Expired"
    case registered = "Registered"
    case validated = "Validated"
    case deleted = "Deleted"
}

enum WalletItemStatusTypeBGE: String {
    case pndActive = "pnd_active"
    case pndWait = "pnd_wait"
    case active = "active"
    case cancel = "cancel"
    case bad_active = "bad_active"
    case deleted = "deleted"
}

// Comed/PECO
enum PaymentCategoryType: String {
    case check = "Check"
    case credit = "Credit"
    case debit = "Debit"
}

// Comed/PECO
enum PaymentMethodType: String {
    case visa = "VISA"
    case mastercard = "MASTERCARD"
    case americanexpress = "AMERICANEXPRESS"
    case discover = "DISCOVER"
}

// BGE
enum BankAccountType: String {
    case checking = "checking"
    case savings = "saving"
}


struct WalletItem: Mappable, Equatable, Hashable {
    let walletItemID: String?
    let walletExternalID: String?
    let maskedWalletItemAccountNumber: String?
    var nickName: String?
    let walletItemStatusType: WalletItemStatusType?
    let walletItemStatusTypeBGE: WalletItemStatusTypeBGE?
    let paymentCategoryType: PaymentCategoryType?
    let paymentMethodType: PaymentMethodType?
    
    let bankAccountType: BankAccountType?
    let isNOCViewed: Bool
    let bankAccountNumber: String?
    let bankAccountName: String?
    
    
    init(map: Mapper) throws {
        // All
        walletItemID = map.optionalFrom("walletItemID")
        walletExternalID = map.optionalFrom("walletExternalID")
        
        maskedWalletItemAccountNumber = map.optionalFrom("maskedWalletItemAccountNumber")
        
        nickName = map.optionalFrom("nickName")
        if let nickname = nickName {
            if nickname.isEmpty { // prevent empty strings
                nickName = nil
            }
        }
        
        if Environment.sharedInstance.opco == .bge {
            walletItemStatusTypeBGE = map.optionalFrom("walletItemStatusType")
            walletItemStatusType = nil
        } else {
            walletItemStatusTypeBGE = nil
            walletItemStatusType = map.optionalFrom("walletItemStatusType")
        }
        
        // Comed/PECO
        paymentCategoryType = map.optionalFrom("paymentCategoryType")
        paymentMethodType = map.optionalFrom("paymentMethodType")
        
        // BGE
        bankAccountType = map.optionalFrom("bankAccountType")
        isNOCViewed = map.optionalFrom("flagnocViewed") ?? false
        bankAccountNumber = map.optionalFrom("bankAccountNumber")
        bankAccountName = map.optionalFrom("bankAccountName")
    }
    
    
    // Equatable
    static func ==(lhs: WalletItem, rhs: WalletItem) -> Bool {
        return lhs.walletItemID == rhs.walletItemID
    }
    
    // Hashable
    var hashValue: Int {
        return walletItemID!.hash
    }
}
