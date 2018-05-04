//
//  Wallet.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Mapper

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
    let walletItemStatusType: String?
    var isExpired: Bool = false
    
    let paymentCategoryType: PaymentCategoryType? // Do not use this for determining bank vs card - use bankOrCard
    let bankAccountType: BankAccountType? // Do not use this for determining bank vs card - use bankOrCard
    var bankOrCard: BankOrCard = .card
    
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
        dateCreated = map.optionalFrom("dateCreated", transformation: extractDate)
        
        walletItemStatusType = map.optionalFrom("walletItemStatusType")
        if let statusType = walletItemStatusType {
            isExpired = statusType.lowercased() == "expired"
        }
        
        if let type = bankAccountType, Environment.sharedInstance.opco == .bge {
            bankOrCard = type == .card ? .card : .bank
        } else if let type = paymentCategoryType {
            bankOrCard = (type == .credit || type == .debit) ? .card : .bank
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
