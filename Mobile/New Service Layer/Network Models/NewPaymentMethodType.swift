////
////  NewPaymentMethodType.swift
////  Mobile
////
////  Created by Joseph Erlandson on 3/9/20.
////  Copyright © 2020 Exelon Corporation. All rights reserved.
////
//
//import UIKit
//
//enum NewPaymentMethodType: Codable {
//    init(from decoder: Decoder) throws {
//        <#code#>
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        <#code#>
//    }
//    
//    case ach
//    case visa
//    case mastercard
//    case amex
//    case discover
//    case unknown(String)
//    
//    init(_ paymentMethodType: String) {
//        switch paymentMethodType {
//        case "ACH":
//            self = .ach
//        case "VISA":
//            self = .visa
//        case "MASTERCARD":
//            self = .mastercard
//        case "AMEX":
//            self = .amex
//        case "DISCOVER":
//            self = .discover
//        default:
//            self = .unknown(paymentMethodType)
//        }
//    }
//    
//    var rawString: String {
//        switch self {
//        case .ach:
//            return "ACH"
//        case .visa:
//            return "VISA"
//        case .mastercard:
//            return "MASTERCARD"
//        case .amex:
//            return "AMEX"
//        case .discover:
//            return "DISCOVER"
//        case .unknown(let raw):
//            return raw
//        }
//    }
//    
//    var imageLarge: UIImage {
//        switch self {
//        case .visa:
//            return #imageLiteral(resourceName: "ic_visa_large")
//        case .mastercard:
//            return #imageLiteral(resourceName: "ic_mastercard_large")
//        case .amex:
//            return #imageLiteral(resourceName: "ic_amex_large")
//        case .discover:
//            return #imageLiteral(resourceName: "ic_discover_large")
//        case .ach:
//            return #imageLiteral(resourceName: "opco_bank")
//        case .unknown(_):
//            return #imageLiteral(resourceName: "opco_credit_card")
//        }
//    }
//    
//    var imageMini: UIImage {
//        switch self {
//        case .visa:
//            return #imageLiteral(resourceName: "ic_visa_mini")
//        case .mastercard:
//            return #imageLiteral(resourceName: "ic_mastercard_mini")
//        case .amex:
//            return #imageLiteral(resourceName: "ic_amex_mini")
//        case .discover:
//            return #imageLiteral(resourceName: "ic_discover_mini")
//        case .ach:
//            return #imageLiteral(resourceName: "opco_bank_mini")
//        case .unknown(_):
//            return #imageLiteral(resourceName: "credit_card_mini")
//        }
//    }
//    
//    var displayString: String {
//        switch self {
//        case .ach:
//            return NSLocalizedString("ACH", comment: "")
//        case .visa:
//            return NSLocalizedString("Visa", comment: "")
//        case .mastercard:
//            return NSLocalizedString("MasterCard", comment: "")
//        case .amex:
//            return NSLocalizedString("American Express", comment: "")
//        case .discover:
//            return NSLocalizedString("Discover", comment: "")
//        case .unknown(let value):
//            return value
//        }
//    }
//    
//    var accessibilityString: String {
//        switch self {
//        case .ach:
//            return NSLocalizedString("Bank account", comment: "")
//        default:
//            return displayString
//        }
//    }
//}
