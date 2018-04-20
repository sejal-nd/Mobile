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

// Used internally for Payment model
enum PaymentType: String {
    case check = "Check"
    case credit = "Card"
}

// Comed/PECO
enum PaymentCategoryType: String {
    case check = "Check"
    case credit = "Credit"
    case debit = "Debit"
}

// BGE
enum BankAccountType: String {
    case checking = "checking"
    case savings = "saving"
    case card = "card"
}

// We consolidate PaymentCategoryType & BankAccountType into this
enum BankOrCard {
    case bank
    case card
}

private func extractLast4(object: Any?) throws -> String? {
    guard let string = object as? String else {
        throw MapperError.convertibleError(value: object, type: String.self)
    }
    return string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
}

private func extractDate(object: Any?) throws -> Date {
    guard let dateString = object as? String else {
        throw MapperError.convertibleError(value: object, type: Date.self)
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = .opCo
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    if let date = dateFormatter.date(from: dateString) {
        return date
    }
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    if let date = dateFormatter.date(from: dateString) {
        return date
    }
    
    throw MapperError.convertibleError(value: object, type: Date.self)
}

struct WalletItem: Mappable, Equatable, Hashable {
    let walletItemID: String?
    let walletExternalID: String?
    let maskedWalletItemAccountNumber: String?
    var nickName: String?
    let walletItemStatusType: WalletItemStatusType?
    let walletItemStatusTypeBGE: WalletItemStatusTypeBGE?
    
    let paymentCategoryType: PaymentCategoryType? // Do not use this for determining bank vs card - use bankOrCard
    let bankAccountType: BankAccountType? // Do not use this for determining bank vs card - use bankOrCard
    var bankOrCard: BankOrCard
    
    let bankAccountNumber: String?
    let bankAccountName: String?
    let isDefault: Bool
    
    let cardIssuer: String?
    
    let dateCreated: Date?
    
    init(map: Mapper) throws {
        walletItemID = map.optionalFrom("walletItemID")
        walletExternalID = map.optionalFrom("walletExternalID")
        
        maskedWalletItemAccountNumber = map.optionalFrom("maskedWalletItemAccountNumber", transformation: extractLast4)
        
        nickName = map.optionalFrom("nickName")
        if let nickname = nickName {
            if nickname.isEmpty { // prevent empty strings
                nickName = nil
            }
        }
        
        paymentCategoryType = map.optionalFrom("paymentCategoryType")
        bankAccountType = map.optionalFrom("bankAccountType")
        bankAccountNumber = map.optionalFrom("bankAccountNumber")
        bankAccountName = map.optionalFrom("bankAccountName")
        isDefault = map.optionalFrom("isDefault") ?? false
        cardIssuer = map.optionalFrom("cardIssuer")
        bankOrCard = .card // default value
        dateCreated = map.optionalFrom("dateCreated", transformation: extractDate)
        
        if Environment.sharedInstance.opco == .bge {
            walletItemStatusTypeBGE = map.optionalFrom("walletItemStatusType")
            walletItemStatusType = nil
            if let type = bankAccountType {
                bankOrCard = type == .card ? .card : .bank
            }
        } else {
            walletItemStatusTypeBGE = nil
            walletItemStatusType = map.optionalFrom("walletItemStatusType")
            if let type = paymentCategoryType {
                bankOrCard = (type == .credit || type == .debit) ? .card : .bank
            }
        }
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
