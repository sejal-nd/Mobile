//
//  WalletItem.swift
//  BGE
//
//  Created by Cody Dillon on 8/11/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct WalletItem: Decodable, Equatable {
    public var walletItemId: String?
    public var maskedAccountNumber: String?
    public var nickName: String?
    public var paymentCategoryType: PaymentCategoryType
    public var paymentMethodType: PaymentMethodType
    public var bankName: String?
    public var isDefault: Bool
    public var expirationDate: Date?
    
    var isTemporary: Bool = false // Indicates payment method NOT saved to wallet
    var isEditingItem: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case walletItemId = "walletItemID"
        case maskedAccountNumber = "maskedWalletItemAccountNumber"
        case nickName
        case paymentCategoryType
        case paymentMethodType
        case bankName
        case isDefault
        case expirationDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        walletItemId = try container.decode(String.self, forKey: .walletItemId)
        maskedAccountNumber = try container.decode(String.self, forKey: .maskedAccountNumber)
        nickName = try container.decodeIfPresent(String.self, forKey: .nickName)
        if let n = nickName, n.isEmpty {
            nickName = nil
        }
        paymentCategoryType = try container.decode(PaymentCategoryType.self, forKey: .paymentCategoryType)
        
        let methodType = try container.decode(String.self, forKey: .paymentMethodType)
        paymentMethodType = PaymentMethodType(methodType)
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
    }
    
    // Used both for Unit/UI Tests AND for the creation of the temporary wallet items from Paymentus iFrame
    public init(walletItemId: String? = "1234",
         maskedAccountNumber: String? = "1234",
         nickName: String? = nil,
         paymentMethodType: PaymentMethodType?,
         bankName: String? = "M&T Bank",
         expirationDate: String? = "01/2100",
         isDefault: Bool = false,
         isTemporary: Bool = false,
         isEditingItem: Bool = false) {
        self.walletItemId = walletItemId
        self.maskedAccountNumber = maskedAccountNumber
        self.nickName = nickName
        self.paymentMethodType = paymentMethodType ?? .ach
        
        switch paymentMethodType {
        case .ach:
            paymentCategoryType = .check
        default:
            paymentCategoryType = .credit
        }
        
        self.bankName = bankName
        self.expirationDate = try? DateParser().extractDate(object: expirationDate)
        self.isDefault = isDefault
        self.isTemporary = isTemporary
        self.isEditingItem = isEditingItem
    }
    
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
    
    var categoryType: String {
        return bankOrCard == .bank ? "check" : "credit"
    }
    
    // Equatable
    public static func ==(lhs: WalletItem, rhs: WalletItem) -> Bool {
        return lhs.walletItemId == rhs.walletItemId
    }
    
    func accessibilityDescription(includingDefaultPaymentMethodInfo: Bool = false) -> String {
        var a11yLabel = paymentMethodType.accessibilityString
        
        if let nickname = nickName {
            a11yLabel += ", \(nickname)"
        }
        
        if let last4Digits = maskedAccountNumber {
            a11yLabel += String.localizedStringWithFormat(", Account number ending in, %@", last4Digits)
        }
        
        if includingDefaultPaymentMethodInfo && isDefault {
            a11yLabel += NSLocalizedString(", Default payment method", comment: "")
        }
        
        if isExpired {
            a11yLabel += NSLocalizedString(", expired", comment: "")
        }
        
        return a11yLabel
    }
}

public enum PaymentCategoryType: String, Decodable {
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
public enum BankOrCard {
    case bank
    case card
}

public enum PaymentMethodType {
    case ach
    case visa
    case mastercard
    case amex
    case discover
    case unknown(String)
    
    init(_ paymentMethodType: String) {
        switch paymentMethodType {
        case "ACH":
            self = .ach
        case "VISA":
            self = .visa
        case "MASTERCARD":
            self = .mastercard
        case "AMEX":
            self = .amex
        case "DISCOVER":
            self = .discover
        default:
            self = .unknown(paymentMethodType)
        }
    }
    
    var rawString: String {
        switch self {
        case .ach:
            return "ACH"
        case .visa:
            return "VISA"
        case .mastercard:
            return "MASTERCARD"
        case .amex:
            return "AMEX"
        case .discover:
            return "DISCOVER"
        case .unknown(let raw):
            return raw
        }
    }
    
    var imageLarge: UIImage {
        switch self {
        case .visa:
            return #imageLiteral(resourceName: "ic_visa_large")
        case .mastercard:
            return #imageLiteral(resourceName: "ic_mastercard_large")
        case .amex:
            return #imageLiteral(resourceName: "ic_amex_large")
        case .discover:
            return #imageLiteral(resourceName: "ic_discover_large")
        case .ach:
            return #imageLiteral(resourceName: "opco_bank")
        case .unknown(_):
            return #imageLiteral(resourceName: "opco_credit_card")
        }
    }
    
    var imageMini: UIImage {
        switch self {
        case .visa:
            return #imageLiteral(resourceName: "ic_visa_mini")
        case .mastercard:
            return #imageLiteral(resourceName: "ic_mastercard_mini")
        case .amex:
            return #imageLiteral(resourceName: "ic_amex_mini")
        case .discover:
            return #imageLiteral(resourceName: "ic_discover_mini")
        case .ach:
            return #imageLiteral(resourceName: "opco_bank_mini")
        case .unknown(_):
            return #imageLiteral(resourceName: "credit_card_mini")
        }
    }

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
        case .unknown(let value):
            return value
        }
    }
    
    var accessibilityString: String {
        switch self {
        case .ach:
            return NSLocalizedString("Bank account", comment: "")
        default:
            return displayString
        }
    }
}

// The postMessage event of the Paymentus iFrame sends "pmDetails.Type" as one of these
// Also, these are returned as the "payment_type" from Billing History
fileprivate enum PaymentusPaymentMethodType: String {
    case checking = "CHQ"
    case saving = "SAV"
    case visa = "VISA"
    case mastercard = "MC"
    case amex = "AMEX"
    case discover = "DISC"
    case visaDebit = "VISA_DEBIT"
    case mastercardDebit = "MC_DEBIT"
}

func paymentMethodTypeForPaymentusString(_ paymentusString: String) -> PaymentMethodType {
    if let type = PaymentusPaymentMethodType(rawValue: paymentusString) {
        switch type {
        case .checking, .saving:
            return .ach
        case .visa, .visaDebit:
            return .visa
        case .mastercard, .mastercardDebit:
            return .mastercard
        case .amex:
            return .amex
        case .discover:
            return .discover
        }
    } else {
        return .unknown(paymentusString)
    }
}
