//
//  Wallet.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

// Used internally for Payment model
enum PaymentType: String {
    case check = "Check"
    case credit = "Card"
}

// Comed/PECO
enum PaymentCategoryType: String {
    case check = "CHECK"
    case saving = "SAVING"
    case credit = "CREDIT"
    case debit = "DEBIT"
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
    
    let last4 = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
        .joined()
        .suffix(4)
    
    return String(last4)
}

struct WalletItem: Mappable, Equatable, Hashable {
    let walletItemID: String?
    let walletExternalID: String? // TODO: Remove for BGE when they switch to paymentus
    let maskedWalletItemAccountNumber: String?
    var nickName: String?
    let walletItemStatusType: String? // Not sent for paymentus wallet items. TODO: Remove for BGE when they switch to paymentus
    var isExpired: Bool {
        if Environment.shared.opco == .bge {
            return walletItemStatusType?.lowercased() == "expired"
        } else if let exp = expirationDate {
            let monthYearSet = Set<Calendar.Component>(arrayLiteral: .month, .year)
            let expComponents = Calendar.gmt.dateComponents(monthYearSet, from: exp)
            let todayComponents = Calendar.gmt.dateComponents(monthYearSet, from: Date())
            guard let expMonth = expComponents.month, let expYear = expComponents.year,
                let todayMonth = todayComponents.month, let todayYear = todayComponents.year else {
                return false
            }
            if todayYear > expYear || (todayYear == expYear && todayMonth > expMonth) {
                return true
            }
        }
        return false
    }
    let expirationDate: Date? // Paymentus only field
    
    let paymentCategoryType: PaymentCategoryType? // Do not use this for determining bank vs card - use bankOrCard
    let bankAccountType: BankAccountType? // Do not use this for determining bank vs card - use bankOrCard
    var bankOrCard: BankOrCard = .card
    var isTemporary: Bool // Indicates temporary Paymentus wallet item
    
    let bankAccountNumber: String?
    let bankAccountName: String?
    let isDefault: Bool
    
    let cardIssuer: String?
    
    let dateCreated: Date? // Not sent for paymentus wallet items. TODO: Remove for BGE when they switch to paymentus
    
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
        dateCreated = map.optionalFrom("dateCreated", transformation: DateParser().extractDate)
        
        walletItemStatusType = map.optionalFrom("walletItemStatusType")
        expirationDate = map.optionalFrom("expirationDate", transformation: DateParser().extractDate)
        
        if let type = bankAccountType, Environment.shared.opco == .bge {
            bankOrCard = type == .card ? .card : .bank
        } else if let type = paymentCategoryType {
            switch type {
            case .credit, .debit:
                bankOrCard = .card
            case .check, .saving:
                bankOrCard = .bank
            }
        }
        
        isTemporary = false
    }
    
    // Used both for Unit/UI Tests AND for the creation of the temporary wallet items from Paymentus iFrame
    init(walletItemID: String? = "1234",
         walletExternalID: String? = "1234",
         maskedWalletItemAccountNumber: String? = "1234",
         nickName: String? = nil,
         walletItemStatusType: String? = "active",
         expirationDate: String? = "01/2100",
         bankAccountNumber: String? = nil,
         bankAccountName: String? = nil,
         isDefault: Bool = false,
         cardIssuer: String? = nil,
         bankOrCard: BankOrCard = .bank,
         isTemporary: Bool = false) {
        
        var map = [String: Any]()
        map["walletItemID"] = walletItemID
        map["walletExternalID"] = walletExternalID
        map["maskedWalletItemAccountNumber"] = maskedWalletItemAccountNumber
        map["nickName"] = nickName
        map["walletItemStatusType"] = walletItemStatusType
        map["bankAccountNumber"] = bankAccountNumber
        map["bankAccountName"] = bankAccountName
        map["isDefault"] = isDefault
        map["cardIssuer"] = cardIssuer
        map["expirationDate"] = expirationDate
        
        self = WalletItem.from(map as NSDictionary)!
        self.bankOrCard = bankOrCard
        self.isTemporary = isTemporary
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
