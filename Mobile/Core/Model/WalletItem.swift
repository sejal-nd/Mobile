//
//  Wallet.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

private enum PaymentCategoryType: String {
    case check = "CHECK"
    case saving = "SAVING"
    case credit = "CREDIT"
    case debit = "DEBIT"
}

// We consolidate PaymentCategoryType into this
enum BankOrCard {
    case bank
    case card
}

enum PaymentMethodType: String {
    case ach = "ACH"
    case visa = "VISA"
    case mastercard = "MC"
    case amex = "AMEX"
    case discover = "DISC"
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
    private let paymentCategoryType: PaymentCategoryType? // private because only bankOrCard should be used
    let paymentMethodType: PaymentMethodType? // ACH, VISA, Mastercard, etc
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
    var bankOrCard: BankOrCard = .bank
    var isTemporary: Bool // Indicates payment method NOT saved to wallet
    
    init(map: Mapper) throws {
        walletItemID = map.optionalFrom("walletItemID")
        maskedWalletItemAccountNumber = map.optionalFrom("maskedWalletItemAccountNumber", transformation: extractLast4)
        
        nickName = map.optionalFrom("nickName")
        if let n = nickName, n.isEmpty {
            nickName = nil
        }
        
        paymentCategoryType = map.optionalFrom("paymentCategoryType")
        if let type = paymentCategoryType {
            switch type {
            case .credit, .debit:
                bankOrCard = .card
            case .check, .saving:
                bankOrCard = .bank
            }
        }
        
        paymentMethodType = map.optionalFrom("paymentMethodType")
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
