//
//  Wallet.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

enum PaymentCategoryType: String {
    case check = "CHECK"
    case saving = "SAVING"
    case credit = "CREDIT"
    case debit = "DEBIT"
    
    var displayString: String {
        switch self {
        case .check:
            return NSLocalizedString("Checking Account", comment: "")
        case .saving:
            return NSLocalizedString("Savings Account", comment: "")
        case .credit:
            return NSLocalizedString("Credit Card", comment: "")
        case .debit:
            return NSLocalizedString("Debit Card", comment: "")
        }
    }
}

// We consolidate PaymentCategoryType into this
enum BankOrCard {
    case bank
    case card
}

enum PaymentMethodType: String {
    case ach = "ACH"
    case visa = "VISA"
    case mastercard = "MASTERCARD"
    case amex = "AMEX"
    case discover = "DISCOVER"
    
    var displayString: String {
        switch self {
        case .ach:
            return NSLocalizedString("ACH", comment: "")
        case .visa:
            return NSLocalizedString("Visa", comment: "")
        case .mastercard:
            return NSLocalizedString("MasterCard", comment: "")
        case .amex:
            return NSLocalizedString("American Express", comment: "")
        case .discover:
            return NSLocalizedString("Discover", comment: "")
        }
    }
}

/* MCS sends something like "************1111", but we do the transform so that
 * maskedWalletItemAccountNumber is just a 4 character string */
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
    let maskedWalletItemAccountNumber: String?
    var nickName: String?
    let paymentCategoryType: PaymentCategoryType
    let paymentMethodType: PaymentMethodType
    let bankName: String?
    let expirationDate: Date?
    let isDefault: Bool
    
    var isExpired: Bool {
        if let exp = expirationDate {
            let monthYearSet = Set<Calendar.Component>(arrayLiteral: .month, .year)
            let expComponents = Calendar.gmt.dateComponents(monthYearSet, from: exp)
            let todayComponents = Calendar.gmt.dateComponents(monthYearSet, from: .now)
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
    
    var bankOrCard: BankOrCard {
        switch paymentCategoryType {
        case .credit, .debit:
            return .card
        case .check, .saving:
            return .bank
        }
    }
    
    var isTemporary: Bool // Indicates payment method NOT saved to wallet
    
    init(map: Mapper) throws {
        walletItemID = map.optionalFrom("walletItemID")
        maskedWalletItemAccountNumber = map.optionalFrom("maskedWalletItemAccountNumber", transformation: extractLast4)
        
        nickName = map.optionalFrom("nickName")
        if let n = nickName, n.isEmpty {
            nickName = nil
        }
        
        try paymentCategoryType = map.from("paymentCategoryType")
        try paymentMethodType = map.from("paymentMethodType")
        bankName = map.optionalFrom("bankName")
        expirationDate = map.optionalFrom("expirationDate", transformation: DateParser().extractDate)
        isDefault = map.optionalFrom("isDefault") ?? false
        
        isTemporary = false
    }
    
    // Used both for Unit/UI Tests AND for the creation of the temporary wallet items from Paymentus iFrame
    init(walletItemID: String? = "1234",
         maskedWalletItemAccountNumber: String? = "1234",
         nickName: String? = nil,
         paymentMethodType: PaymentMethodType? = nil,
         bankName: String? = "M&T Bank",
         expirationDate: String? = "01/2100",
         isDefault: Bool = false,
         bankOrCard: BankOrCard = .bank,
         isTemporary: Bool = false) {
        
        var map = [String: Any]()
        map["walletItemID"] = walletItemID
        map["maskedWalletItemAccountNumber"] = maskedWalletItemAccountNumber
        map["nickName"] = nickName
        map["paymentCategoryType"] = bankOrCard == .bank ? "CHECK" : "CREDIT"
        if let pmt = paymentMethodType {
            map["paymentMethodType"] = pmt.rawValue
        } else {
            map["paymentMethodType"] = bankOrCard == .bank ?
                PaymentMethodType.ach.rawValue :
                PaymentMethodType.visa.rawValue
        }
        map["bankName"] = bankName
        map["expirationDate"] = expirationDate
        map["isDefault"] = isDefault
        
        self = WalletItem.from(map as NSDictionary)!
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
